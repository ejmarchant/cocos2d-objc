//
//  AppDelegate.m
//  cocos2d-ui-tests-osx
//
//  Created by Viktor on 9/16/13.
//  Copyright Cocos2d 2013. All rights reserved.
//

#import "AppDelegate.h"
#import "IntroScene.h"

@implementation cocos2d_ui_tests_osxAppDelegate
@synthesize window=window_, glView=glView_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
    
    // enable FPS and SPF
    [director setDisplayStats:YES];
    
    CGSize defaultWinSize = CGSizeMake(1136, 640);
    [window_ setFrame:CGRectMake(0, 0, defaultWinSize.width, defaultWinSize.height) display:YES];
    glView_.frame = window_.frame;
    
    // connect the OpenGL view with the director
    [director setView:glView_];
    
    // Enable "moving" mouse event. Default no.
    [window_ setAcceptsMouseMovedEvents:NO];
    
    // Center main window
    [window_ center];
    
    [CCImageResizer sharedInstance].enableResizing = YES;
    [CCImageResizer sharedInstance].baseAssetScaleFactor = 2.0;
    CGFloat uiScaleFactor = 1.0;
    [CCDirector sharedDirector].UIScaleFactor = uiScaleFactor;
    [CCImageResizer sharedInstance].assetUIScaleFactor = uiScaleFactor;
    
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
    
    [director runWithScene:[[IntroScene alloc] init]];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
	return YES;
}

- (void)dealloc
{
	[[CCDirector sharedDirector] end];
}

#pragma mark AppDelegate - IBActions

- (IBAction)toggleFullScreen: (id)sender
{
	CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
	[director setFullScreen: ! [director isFullScreen] ];
}

@end
