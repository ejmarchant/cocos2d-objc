//
//  CCImageResizer.h
//  cocos2d
//
//  Created by Edward Marchant on 15/06/2016.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

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
// The resizing scale factor is:
//   _assetUIScaleFactor * [[CCDirector sharedDirector] contentScaleFactor] / _baseAssetScaleFactor

-(CCTexture*)resizedTextureOfBaseTextureWithName:(NSString*)fileName;

@end
