/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2013-2014 Cocos2D Authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "ccMacros.h"
#import "Platforms/CCGL.h"
#import "CCTextureCache.h"
#import "CCTexture.h"
#import "CCTexturePVR.h"
#import "CCConfiguration.h"
#import "CCDirector.h"
#import "ccConfig.h"
#import "ccTypes.h"
#import "CCImageResizer.h"

#import "Support/CCFileUtils.h"
#import "Support/NSThread+performBlock.h"

#import <objc/message.h>


#if __CC_PLATFORM_MAC
#import "Platforms/Mac/CCDirectorMac.h"
#endif

#import "CCRenderer_Private.h"

// needed for CCCallFuncO in Mac-display_link version
//#import "CCActionManager.h"
//#import "CCActionInstant.h"

#if __CC_PLATFORM_IOS
static EAGLContext *_auxGLcontext = nil;
#elif __CC_PLATFORM_MAC
static NSOpenGLContext *_auxGLcontext = nil;
#endif

@implementation CCTextureCache

#pragma mark TextureCache - Alloc, Init & Dealloc
static CCTextureCache *sharedTextureCache;

+ (CCTextureCache *)sharedTextureCache
{
	if (!sharedTextureCache)
		sharedTextureCache = [[self alloc] init];

	return sharedTextureCache;
}

+(id)alloc
{
	NSAssert(sharedTextureCache == nil, @"Attempted to allocate a second instance of a singleton.");
	return [super alloc];
}

+(void)purgeSharedTextureCache
{
	sharedTextureCache = nil;
}

-(id) init
{
	if( (self=[super init]) ) {
		_textures = [NSMutableDictionary dictionaryWithCapacity: 10];
		
		// init "global" stuff
		_loadingQueue = dispatch_queue_create("org.cocos2d.texturecacheloading", NULL);
		_dictQueue = dispatch_queue_create("org.cocos2d.texturecachedict", NULL);
		
		// Skip the GL context sharegroup code for Metal.
		if([CCConfiguration sharedConfiguration].graphicsAPI == CCGraphicsAPIMetal) return self;
		
		CCGLView *view = (CCGLView*)[[CCDirector sharedDirector] view];
		NSAssert(view, @"Do not initialize the TextureCache before the Director");

#if __CC_PLATFORM_IOS
		_auxGLcontext = [[EAGLContext alloc]
						 initWithAPI:kEAGLRenderingAPIOpenGLES2
						 sharegroup:[[view context] sharegroup]];

#elif __CC_PLATFORM_MAC
		NSOpenGLPixelFormat *pf = [view pixelFormat];
		NSOpenGLContext *share = [view openGLContext];

		_auxGLcontext = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:share];

#endif // __CC_PLATFORM_MAC
        
		NSAssert( _auxGLcontext, @"TextureCache: Could not create EAGL context");

	}

	return self;
}

- (NSString*) description
{
	__block NSString *desc = nil;
	dispatch_sync(_dictQueue, ^{
		desc = [NSString stringWithFormat:@"<%@ = %p | num of textures =  %lu | keys: %@>",
			[self class],
			self,
            (unsigned long)[self->_textures count],
            [self->_textures allKeys]
			];
	});
	return desc;
}

-(void) dealloc
{
	CCLOGINFO(@"cocos2d: deallocing %@", self);

	_auxGLcontext = nil;
    
	sharedTextureCache = nil;
    
	// dispatch_release(_loadingQueue);
	// dispatch_release(_dictQueue);
    
}

#pragma mark TextureCache - Add Images

-(void) addImageAsync: (NSString*)path target:(id)target selector:(SEL)selector
{
	NSAssert(path != nil, @"TextureCache: fileimage MUST not be nill");
	NSAssert(target != nil, @"TextureCache: target can't be nil");
	NSAssert(selector != NULL, @"TextureCache: selector can't be NULL");

	// remove possible -HD suffix to prevent caching the same image twice (issue #1040)
	CCFileUtils *fileUtils = [CCFileUtils sharedFileUtils];
	path = [fileUtils standarizePath:path];

	// optimization
	__block CCTexture * tex;
		
	dispatch_sync(_dictQueue, ^{
		tex = [self->_textures objectForKey:path];
	});

	if(tex) {
		typedef void (*Func)(id, SEL, id);
		((Func)objc_msgSend)(target, selector, tex);
		return;
	}

	// dispatch it serially
	dispatch_async(_loadingQueue, ^{

		CCTexture *texture;

#if __CC_PLATFORM_IOS
		if( [EAGLContext setCurrentContext:_auxGLcontext] ) {

			// load / create the texture
			texture = [self addImage:path];

			glFlush();

			// callback should be executed in cocos2d thread
			[target performSelector:selector onThread:[[CCDirector sharedDirector] runningThread] withObject:texture waitUntilDone:NO];

			[EAGLContext setCurrentContext:nil];
		} else {
			CCLOG(@"cocos2d: ERROR: TetureCache: Could not set EAGLContext");
		}

#elif __CC_PLATFORM_MAC

		[_auxGLcontext makeCurrentContext];

		// load / create the texture
		texture = [self addImage:path];

		glFlush();

		// callback should be executed in cocos2d thread
		[target performSelector:selector onThread:[[CCDirector sharedDirector] runningThread] withObject:texture waitUntilDone:NO];

		[NSOpenGLContext clearCurrentContext];

#endif // __CC_PLATFORM_MAC

	});
}

-(void) addImageAsync:(NSString*)path withBlock:(void(^)(CCTexture *tex))block
{
	NSAssert(path != nil, @"TextureCache: fileimage MUST not be nil");

	// remove possible -HD suffix to prevent caching the same image twice (issue #1040)
	CCFileUtils *fileUtils = [CCFileUtils sharedFileUtils];
	path = [fileUtils standarizePath:path];

	// optimization
	__block CCTexture * tex;

	dispatch_sync(_dictQueue, ^{
		tex = [self->_textures objectForKey:path];
	});

	if(tex) {
		block(tex);
		return;
	}

	// dispatch it serially
	dispatch_async( _loadingQueue, ^{

		CCTexture *texture;

#if __CC_PLATFORM_IOS
		if( [EAGLContext setCurrentContext:_auxGLcontext] ) {

			// load / create the texture
			texture = [self addImage:path];

			glFlush();
            
            [EAGLContext setCurrentContext:nil];

			// callback should be executed in cocos2d thread
			NSThread *thread = [[CCDirector sharedDirector] runningThread];
			[thread performBlock:block withObject:texture waitUntilDone:NO];
        
		} else {
			CCLOG(@"cocos2d: ERROR: TetureCache: Could not set EAGLContext");
		}

#elif __CC_PLATFORM_MAC

		[_auxGLcontext makeCurrentContext];

		// load / create the texture
		texture = [self addImage:path];

		glFlush();
        
        [NSOpenGLContext clearCurrentContext];

		// callback should be executed in cocos2d thread
		NSThread *thread = [[CCDirector sharedDirector] runningThread];
		[thread performBlock:block withObject:texture waitUntilDone:NO];

#endif // __CC_PLATFORM_MAC

	});
}

-(CCTexture*) addImage: (NSString*) path
{
	NSAssert(path != nil, @"TextureCache: fileimage MUST not be nil");

	// remove possible -HD suffix to prevent caching the same image twice (issue #1040)
	CCFileUtils *fileUtils = [CCFileUtils sharedFileUtils];
	path = [fileUtils standarizePath:path];

	__block CCTexture *tex = nil;

	dispatch_sync(_dictQueue, ^{
		tex = [self->_textures objectForKey: path];
	});
    if (tex) {
        return (id)(tex.proxy);
    }

    // We will try in order:
    // - autoresizing a base texture
    // - finding an image in an asset catalog
    // - creating a placeholder texture
    
    // Autoresize
    if (!tex) {
        tex = [[CCImageResizer sharedInstance] resizedTextureOfBaseTextureWithName:path];
    }
    
    // Asset catalog
    if (!tex) {
#if __CC_PLATFORM_IOS
        UIImage *image = [UIImage imageNamed:path];
        if (image) {
            tex = [[CCTexture alloc] initWithCGImage:image.CGImage contentScale:image.scale];
        }
#elif __CC_PLATFORM_MAC
        NSImage *image = [NSImage imageNamed:path];
        if (image) {
            CGImageRef cgImage = [image CGImageForProposedRect:nil context:nil hints:nil];
            CGFloat scale = CGImageGetWidth(cgImage) / image.size.width;
            tex = [[CCTexture alloc] initWithCGImage:cgImage contentScale:scale];
        }
#endif
    }
    
    // Construct a placeholder white 1x1 image
    if (!tex) {
#if __CC_PLATFORM_IOS
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextFillRect(context, rect);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        tex = [[CCTexture alloc] initWithCGImage:image.CGImage contentScale:image.scale];
#elif __CC_PLATFORM_MAC
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
        [image lockFocus];
        [[NSColor whiteColor] setFill];
        [NSBezierPath fillRect:NSMakeRect(0, 0, 1, 1)];
        [image unlockFocus];
        tex = [[CCTexture alloc] initWithCGImage:[image CGImageForProposedRect:nil context:nil hints:nil] contentScale:1];
#endif
        CCLOG(@"cocos2d: Couldn't create texture for file: %@ in CCTextureCache.", path);
    }
        
    // Add to the cache
    if (tex) {
        dispatch_sync(_dictQueue, ^{
            [self->_textures setObject: tex forKey:path];
        });
    } else {
        tex = [CCTexture none];
    }
	
	return (id)(tex.proxy);
}


-(CCTexture*) addCGImage: (CGImageRef) imageref forKey: (NSString *)key
{
	NSAssert(imageref != nil, @"TextureCache: image MUST not be nill");

	__block CCTexture * tex = nil;

	// If key is nil, then create a new texture each time
	if( key ) {
		dispatch_sync(_dictQueue, ^{
			tex = [self->_textures objectForKey:key];
		});
		if(tex)
			return((id)tex.proxy);
	}

	tex = [[CCTexture alloc] initWithCGImage:imageref contentScale:1.0];

	if(tex && key){
		dispatch_sync(_dictQueue, ^{
			[self->_textures setObject: tex forKey:key];
		});
	}else{
		CCLOG(@"cocos2d: Couldn't add CGImage in CCTextureCache");
        tex = [CCTexture none];
	}

	return (id)(tex.proxy);
}

#pragma mark TextureCache - Remove

-(void) removeAllTextures
{
	dispatch_sync(_dictQueue, ^{
		[self->_textures removeAllObjects];
	});
}

-(void) removeUnusedTextures
{
    dispatch_sync(_dictQueue, ^{
        NSArray *keys = [self->_textures allKeys];
        for(id key in keys)
        {
            CCTexture *texture = [self->_textures objectForKey:key];
            CCLOGINFO(@"texture: %@", texture);
            // If the weakly retained proxy object is nil, then the texture is unreferenced.
            if (!texture.hasProxy)
            {
                CCLOGINFO(@"cocos2d: CCTextureCache: removing unused texture: %@", key);
                [self->_textures removeObjectForKey:key];
            }
        }
        CCLOGINFO(@"Purge complete.");
    });
}

-(void) removeTexture: (CCTexture*) tex
{
	if( ! tex )
		return;

	dispatch_sync(_dictQueue, ^{
		NSArray *keys = [self->_textures allKeysForObject:tex];

		for( NSUInteger i = 0; i < [keys count]; i++ )
			[self->_textures removeObjectForKey:[keys objectAtIndex:i]];
	});
}

-(void) removeTextureForKey:(NSString*)name
{
	if( ! name )
		return;

	dispatch_sync(_dictQueue, ^{
		[self->_textures removeObjectForKey:name];
	});
}

#pragma mark TextureCache - Get
- (CCTexture *)textureForKey:(NSString *)key
{
	__block CCTexture *tex = nil;

	dispatch_sync(_dictQueue, ^{
		tex = [self->_textures objectForKey:key];
	});

	return((id)tex.proxy);
}

@end


@implementation CCTextureCache (PVRSupport)

-(CCTexture*) addPVRImage:(NSString*)path
{
	NSAssert(path != nil, @"TextureCache: fileimage MUST not be nill");

	// remove possible -HD suffix to prevent caching the same image twice (issue #1040)
	CCFileUtils *fileUtils = [CCFileUtils sharedFileUtils];
	path = [fileUtils standarizePath:path];

	__block CCTexture * tex;
	
	dispatch_sync(_dictQueue, ^{
		tex = [self->_textures objectForKey:path];
	});

	if(tex) {
		return((id)tex.proxy);
	}

	tex = [[CCTexture alloc] initWithPVRFile: path];
	if( tex ){
		dispatch_sync(_dictQueue, ^{
			[self->_textures setObject: tex forKey:path];
		});
	}else{
		CCLOG(@"cocos2d: Couldn't add PVRImage:%@ in CCTextureCache",path);
        tex = [CCTexture none];
	}

	return((id)tex.proxy);
}

@end


@implementation CCTextureCache (Debug)

-(void) dumpCachedTextureInfo
{
	__block NSUInteger count = 0;
	__block NSUInteger totalBytes = 0;

	dispatch_sync(_dictQueue, ^{
		for (NSString* texKey in self->_textures) {
			CCTexture* tex = [self->_textures objectForKey:texKey];
			NSUInteger bpp = [tex bitsPerPixelForFormat];
			// Each texture takes up width * height * bytesPerPixel bytes.
			NSUInteger bytes = tex.pixelWidth * tex.pixelHeight * bpp / 8;
			totalBytes += bytes;
			count++;
			NSLog( @"cocos2d: \"%@\"\tid=%lu\t%lu x %lu\t@ %ld bpp =>\t%lu KB",
				  texKey,
				  (long)tex.name,
				  (long)tex.pixelWidth,
				  (long)tex.pixelHeight,
				  (long)bpp,
				  (long)bytes / 1024 );
		}
	});
	NSLog( @"cocos2d: CCTextureCache dumpDebugInfo:\t%ld textures,\tfor %lu KB (%.2f MB)", (long)count, (long)totalBytes / 1024, totalBytes / (1024.0f*1024.0f));
}

@end
