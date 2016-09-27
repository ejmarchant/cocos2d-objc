/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2013 Apportable Inc.
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
 */

#import "cocos2d.h"

#import "AppDelegate.h"
#import "IntroScene.h"
#import "TestBase.h"
//#import "CCPackageConstants.h"

@implementation AppController

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureCocos2d];

    return YES;
}

- (void)configureCocos2d
{
    [self setupCocos2dWithOptions:@{
        CCSetupDepthFormat: @GL_DEPTH24_STENCIL8,
        CCSetupShowDebugStats: @(getenv("SHOW_DEBUG_STATS") != nil),
    }];
    
    // UI / assets scale factors
    [CCImageResizer sharedInstance].enableResizing = YES;
    [CCImageResizer sharedInstance].baseAssetScaleFactor = 2.0;
    CGFloat uiScaleFactor;
    CGSize size = [[CCDirector sharedDirector] designSize];
    if ([UIScreen mainScreen].traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        uiScaleFactor = MIN(size.width, size.height) / 320.0;
    } else if ([UIScreen mainScreen].traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        uiScaleFactor = 2 * MIN(size.width, size.height) / 768.0;
    } else if ([UIScreen mainScreen].traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomTV) {
        uiScaleFactor = MIN(size.width, size.height) / 320.0;
    } else {
        uiScaleFactor = 1.0;
    }
    [CCDirector sharedDirector].UIScaleFactor = uiScaleFactor;
    [CCImageResizer sharedInstance].assetUIScaleFactor = uiScaleFactor;

    [self configureFileUtilsSearchPathAndRegisterSpriteSheets];

    [[CCDirector sharedDirector] runWithScene:[[IntroScene alloc] init]];
}

- (void)configureFileUtilsSearchPathAndRegisterSpriteSheets
{
    CCFileUtils* sharedFileUtils = [CCFileUtils sharedFileUtils];
    sharedFileUtils.searchDirectories = @[
        @"Images",
        @"Fonts",
        @"Sounds",
        @"Resources-shared/",
        @"Resources-shared/resources"
        ];
    
    // Register spritesheets.
    [[CCSpriteFrameCache sharedSpriteFrameCache] registerSpriteFramesFile:@"Interface.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] registerSpriteFramesFile:@"Sprites.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] registerSpriteFramesFile:@"TilesAtlassed.plist"];
}

/*- (CCScene*) startScene
{
    const char *testName = getenv("Test");
    
    if(testName){
        return [TestBase sceneWithTestName:[NSString stringWithCString:testName encoding:NSUTF8StringEncoding]];
    } else {
        return [MainMenu scene];
    }
}*/

//// I'm going to leave this in for testing the fixed size screen mode in the future.
//- (CCScene*) startScene
//{
////    return [MainMenu scene];
//	CCScene *scene = [CCScene node];
//	
////	// Landscape
////	{
////		// iPad
////		CCNode *node = [CCNodeColor nodeWithColor:[CCColor greenColor] width:512 height:384];
////		node.position = ccp(28, 0);
////		[scene addChild:node];
////	}{
////		// iPhone5
////		CCNode *node = [CCNodeColor nodeWithColor:[CCColor redColor] width:568 height:320];
////		node.position = ccp(0, 32);
////		[scene addChild:node];
////	}{
////		// iPhone
////		CCNode *node = [CCNodeColor nodeWithColor:[CCColor blueColor] width:480 height:320];
////		node.position = ccp(44, 32);
////		[scene addChild:node];
////	}
//	
//	// Portrait
//	{
//		// iPad
//		CCNode *node = [CCNodeColor nodeWithColor:[CCColor greenColor] width:384 height:512];
//		node.position = ccp(0, 28);
//		[scene addChild:node];
//	}{
//		// iPhone5
//		CCNode *node = [CCNodeColor nodeWithColor:[CCColor redColor] width:320 height:568];
//		node.position = ccp(32, 0);
//		[scene addChild:node];
//	}{
//		// iPhone
//		CCNode *node = [CCNodeColor nodeWithColor:[CCColor blueColor] width:320 height:480];
//		node.position = ccp(32, 44);
//		[scene addChild:node];
//	}
//	
//	return scene;
//}

@end
