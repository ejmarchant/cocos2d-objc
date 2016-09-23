//
//  CCPlatformTextField.h
//  cocos2d-osx
//
//  Created by Sergey Klimov on 7/1/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class CCControl;

@class CCPlatformTextField;

@protocol CCPlatformTextFieldDelegate <NSObject>

- (void) platformTextFieldDidFinishEditing:(CCPlatformTextField *) platformTextField;

@end

@interface CCPlatformTextField : NSObject
- (void) positionInControl:(CCControl *)control padding:(CGFloat)padding;
- (void) onEnterTransitionDidFinish;
- (void) onExitTransitionDidStart;
- (void) setFontSize:(float)fontSize;
@property (nonatomic, weak, nullable) id<CCPlatformTextFieldDelegate> delegate;
@property (nonatomic) NSString * string;
@property (nonatomic) BOOL hidden;
@property (nonatomic, readonly) id nativeTextField;
@end

NS_ASSUME_NONNULL_END
