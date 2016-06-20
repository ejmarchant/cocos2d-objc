//
//  CCImageResizer.m
//  cocos2d
//
//  Created by Edward Marchant on 15/06/2016.
//
//

#import "CCImageResizer.h"
#import "CCTexture.h"
#if __CC_PLATFORM_IOS
#import <UIKit/UIKit.h>
#elif __CC_PLATFORM_MAC
#import <Cocoa/Cocoa.h>
#endif
#import "CCDirector.h"
#import "CCFileUtils.h"
#import "CCRenderTexture.h"


@implementation CCImageResizer

+(instancetype)sharedInstance {
    static CCImageResizer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CCImageResizer alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _enableResizing = YES;
        _assetUIScaleFactor = 1.0;
        _baseAssetScaleFactor = 4.0;
    }
    return self;
}

-(CCTexture*)resizedTextureOfBaseTextureWithName:(NSString*)fileName {
    if (!_enableResizing) {
        return nil;
    }
    NSString *fileExtension = [fileName pathExtension];
    if ([fileExtension isEqualToString:@""]) {
        fileName = [fileName stringByAppendingPathExtension:@"png"];
        fileExtension = @"png";
    }
    NSString *path = [[CCFileUtils sharedFileUtils] fullPathForFilename:fileName];
    if (path == nil) {
        return nil;
    }
    NSString *lowerCasePath = [path lowercaseString];
    CCTexture *tex = nil;
    CGFloat contentScale = [[CCDirector sharedDirector] contentScaleFactor];
    CGFloat resizeScale = _assetUIScaleFactor * contentScale / _baseAssetScaleFactor;
    
    if ([[fileExtension lowercaseString] isEqualToString:@"png"]) {
        // --- PNG ---
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        if (data == nil) {
            return nil;
        }
#if __CC_PLATFORM_IOS
        UIImage *image = [[UIImage alloc] initWithData:data];
        if (image) {
            if (ABS(resizeScale - 1) < 0.01) {
                return [[CCTexture alloc] initWithCGImage:image.CGImage contentScale:contentScale];
            }
            CGSize scaledSize = CGSizeMake(floorf(image.size.width * resizeScale), floorf(image.size.height * resizeScale));
            BOOL hasAlpha = YES;
            CGFloat contextScale = 1.0;
            UIGraphicsBeginImageContextWithOptions(scaledSize, !hasAlpha, contextScale);
            [image drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
            UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            tex = [[CCTexture alloc] initWithCGImage:scaledImage.CGImage contentScale:contentScale];
        }
#elif __CC_PLATFORM_MAC
        NSImage *image = [[NSImage alloc] initWithData:data];
        if (image) {
            if (ABS(resizeScale - 1) < 0.01) {
                return [[CCTexture alloc] initWithCGImage:[image CGImageForProposedRect:nil context:nil hints:nil] contentScale:contentScale];
            }
            CGSize scaledSize = CGSizeMake(floorf(image.size.width * resizeScale), floorf(image.size.height * resizeScale));
            NSImage *scaledImage = [[NSImage alloc] initWithSize:scaledSize];
            [scaledImage lockFocus];
            NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
            ctx.imageInterpolation = NSImageInterpolationHigh;
            [image drawInRect: NSMakeRect(0, 0, scaledSize.width, scaledSize.height)
                     fromRect: NSMakeRect(0, 0, image.size.width, image.size.height)
                    operation: NSCompositeSourceOver
                     fraction: 1];
            [scaledImage unlockFocus];
            return [[CCTexture alloc] initWithCGImage:[scaledImage CGImageForProposedRect:nil context:nil hints:nil] contentScale:contentScale];
        }
#endif
        
    } else if ([lowerCasePath hasSuffix:@".pvr"] ||
               [lowerCasePath hasSuffix:@".pvr.gz"] ||
               [lowerCasePath hasSuffix:@".pvr.ccz"]) {
        // --- PVR ---
        CCTexture *bigTex = [[CCTexture alloc] initWithPVRFile:path];
        bigTex.contentScale = contentScale;
        if (ABS(resizeScale - 1) < 0.01) {
            return bigTex;
        }
        int w = (int)(bigTex.pixelWidth * resizeScale / contentScale);
        int h = (int)(bigTex.pixelHeight * resizeScale / contentScale);
        CGFloat scale = MIN(w / (CGFloat)bigTex.pixelWidth, h / (CGFloat)bigTex.pixelHeight) * contentScale;
        CCRenderTexture *rtx = [[CCRenderTexture alloc] initWithWidth:w height:h pixelFormat:CCTexturePixelFormat_RGBA8888];
        CCSprite *sprite = [CCSprite spriteWithTexture:bigTex];
        sprite.scale = scale;
        sprite.anchorPoint = CGPointZero;
        sprite.position = CGPointZero;
        [rtx begin];
        [sprite visit];
        [rtx end];
        tex = rtx.texture;
        tex.contentScale = contentScale;
    }

    return tex;
}

@end
