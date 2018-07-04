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
#import "Support/CCFileUtils.h"
#import "Support/ccUtils.h"
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

-(CGFloat)theoreticalResizingScaleFactor {
    return _assetUIScaleFactor * [[CCDirector sharedDirector] contentScaleFactor] / _baseAssetScaleFactor;
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
    
    if ([[fileExtension lowercaseString] isEqualToString:@"png"] ||
        [[fileExtension lowercaseString] isEqualToString:@"bmp"] ||
        [[fileExtension lowercaseString] isEqualToString:@"jpg"] ||
        [[fileExtension lowercaseString] isEqualToString:@"jpeg"] ||
        [[fileExtension lowercaseString] isEqualToString:@"tiff"]) {
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
            CGSize scaledSize = CGSizeMake(roundf(image.size.width * resizeScale), roundf(image.size.height * resizeScale));
            BOOL hasAlpha = YES;
            CGFloat contextScale = 1.0;
            UIGraphicsBeginImageContextWithOptions(scaledSize, !hasAlpha, contextScale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            // Set the quality level to use when rescaling
            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
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
            CGSize scaledSize = CGSizeMake(roundf(image.size.width * resizeScale), roundf(image.size.height * resizeScale));
            BOOL hasAlpha = YES;
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                                     initWithBitmapDataPlanes: NULL
                                     pixelsWide: scaledSize.width
                                     pixelsHigh: scaledSize.height
                                     bitsPerSample: 8
                                     samplesPerPixel: 4
                                     hasAlpha: hasAlpha
                                     isPlanar: NO
                                     colorSpaceName: NSCalibratedRGBColorSpace
                                     bytesPerRow: 0
                                     bitsPerPixel: 0];
            rep.size = scaledSize;
            [NSGraphicsContext saveGraphicsState];
            NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
            // Set the quality level to use when rescaling
            ctx.imageInterpolation = NSImageInterpolationHigh;
            [NSGraphicsContext setCurrentContext: ctx];
            [image drawInRect: NSMakeRect(0, 0, scaledSize.width, scaledSize.height)
                     fromRect: NSZeroRect
                    operation: NSCompositingOperationCopy
                     fraction: 1.0];
            [NSGraphicsContext restoreGraphicsState];
            NSImage *scaledImage = [[NSImage alloc] initWithSize: scaledSize];
            [scaledImage addRepresentation:rep];
            tex = [[CCTexture alloc] initWithCGImage:[scaledImage CGImageForProposedRect:nil context:nil hints:nil] contentScale:contentScale];
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
        int w = (int)round(bigTex.pixelWidth * resizeScale / contentScale);
        int h = (int)round(bigTex.pixelHeight * resizeScale / contentScale);
        CGFloat scaleX = w / (CGFloat)bigTex.pixelWidth * contentScale;
        CGFloat scaleY = h / (CGFloat)bigTex.pixelHeight * contentScale;
        CCRenderTexture *rtx = [[CCRenderTexture alloc] initWithWidth:w height:h pixelFormat:CCTexturePixelFormat_RGBA8888];
        CCSprite *sprite = [CCSprite spriteWithTexture:bigTex];
        sprite.scaleX = scaleX;
        sprite.scaleY = scaleY;
        sprite.anchorPoint = CGPointZero;
        sprite.position = CGPointZero;
        [rtx begin];
        [sprite visit];
        [rtx end];
        tex = rtx.texture;
        tex.antialiased = YES;
        tex.contentScale = contentScale;
    }
    
    return tex;
}

-(CGSize)integralScaledSize:(CGSize)size {
    CGFloat contentScale = [[CCDirector sharedDirector] contentScaleFactor];
    CGFloat resizeScale = _assetUIScaleFactor * contentScale / _baseAssetScaleFactor;
    CGSize scaledSize = CGSizeMake(roundf(size.width * resizeScale), roundf(size.height * resizeScale));
    return scaledSize;
}

-(CGRect)scaledSubrect:(CGRect)subrect withinBounds:(CGSize)bounds {
    if (!(bounds.width > 0 && bounds.height > 0)) {
        return CGRectZero;
    }
    CGSize scaledBounds = [self integralScaledSize:bounds];
    CGFloat scaleX = scaledBounds.width / bounds.width;
    CGFloat scaleY = scaledBounds.height / bounds.height;
    if (fabs(scaleX - 1.0) > 0.01 || fabs(scaleY - 1.0) > 0.01) {
        // Keep the same center but expand the rect to integral proportions.
        // Note: we may end up with a rect with non-integral origin (but this should look ok).
        CGFloat scaledSubrectWidth = ceilf(subrect.size.width * scaleX);
        CGFloat scaledSubrectHeight = ceilf(subrect.size.height * scaleY);
        CGPoint scaledSubrectCenter = CGPointMake(scaleX * (subrect.origin.x + subrect.size.width * 0.5), scaleY * (subrect.origin.y + subrect.size.height * 0.5));
        CGRect scaledSubrect = CGRectMake(scaledSubrectCenter.x - scaledSubrectWidth * 0.5, scaledSubrectCenter.y - scaledSubrectHeight * 0.5, scaledSubrectWidth, scaledSubrectHeight);
        return scaledSubrect;
    } else {
        return subrect;
    }
}

@end


@implementation CCSprite (makeTexturePowerOfTwo)

-(void)makeTexturePowerOfTwo {
    NSInteger pixelsWide = _texture.pixelWidth;
    NSInteger w = CCNextPOT(pixelsWide);
    NSInteger pixelsHigh = _texture.pixelHeight;
    NSInteger h = CCNextPOT(pixelsHigh);
    if (w == pixelsWide && h == pixelsHigh) {
        return;
    }
    // Replace texture
    CGFloat scaleFactorX = (CGFloat)(w - 1) / (CGFloat)(pixelsWide - 1);
    CGFloat scaleFactorY = (CGFloat)(h - 1) / (CGFloat)(pixelsHigh - 1);
    CCSprite *tempSprite = [CCSprite spriteWithTexture:_texture];
    tempSprite.scaleX = scaleFactorX;
    tempSprite.scaleY = scaleFactorY;
    CCRenderTexture *rtx = [[CCRenderTexture alloc] init];
    [rtx beginWithPixelWidth:w pixelHeight:h];
    tempSprite.anchorPoint = ccp(0.5, 0.5);
    tempSprite.position = ccpMult(ccp((CGFloat)w * 0.5, (CGFloat)h * 0.5), 1.0 / [[CCDirector sharedDirector] contentScaleFactor]);
    [tempSprite visit];
    [rtx end];
    [self setTexture:rtx.sprite.texture];
    [self setBlendMode:[CCBlendMode premultipliedAlphaMode]];
    _texture.antialiased = YES;
    _scaleX = _scaleX * 1.0 / scaleFactorX;
    _scaleY = _scaleY * 1.0 / scaleFactorY;
    return;
}

@end
