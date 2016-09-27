//
//  CCImageResizer.h
//  cocos2d
//
//  Created by Edward Marchant on 15/06/2016.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CCSprite.h"

NS_ASSUME_NONNULL_BEGIN

// Works for png & pvr.
// Note: pvr files will be converted into RGBA8888, so will lose memory advantages.
// Is about 2.5x slower than loading a lower res image when reszing by a factor of 0.5.


@class CCTexture;

@interface CCImageResizer : NSObject

+(instancetype)sharedInstance;

@property(nonatomic, assign) BOOL enableResizing;
// Additional scaling factor.
@property(nonatomic, assign) CGFloat assetUIScaleFactor;
// Base scale factor for asset files.
@property(nonatomic, assign) CGFloat baseAssetScaleFactor;
// The theoretical resizing scale factor is:
//   _assetUIScaleFactor * [[CCDirector sharedDirector] contentScaleFactor] / _baseAssetScaleFactor
// Actual scale factor may be slightly different in either x or y axes depending on if we want to resize to an integral size.
@property(nonatomic, readonly) CGFloat theoreticalResizingScaleFactor;

-(nullable CCTexture*)resizedTextureOfBaseTextureWithName:(NSString*)fileName;

-(CGSize)integralScaledSize:(CGSize)size;
-(CGRect)scaledSubrect:(CGRect)subrect withinBounds:(CGSize)bounds;

@end


// Auto resizing may change a texture asset from power-of-two to non-power-of-two.
// Should use this method on a sprite if we require its texture to be power-of-two.
// e.g. before setting a texture parameter of GL_REPEAT.
@interface CCSprite (makeTexturePowerOfTwo)
-(void)makeTexturePowerOfTwo;
@end

NS_ASSUME_NONNULL_END
