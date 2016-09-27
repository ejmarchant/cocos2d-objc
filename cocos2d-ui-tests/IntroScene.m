//
//  IntroScene.m
//  cocos2d-tests
//
//  Created by Edward Marchant on 24/09/2016.
//  Copyright © 2016 Cocos2d. All rights reserved.
//

#import "IntroScene.h"
#import "MainMenu.h"

@implementation IntroScene

-(void)onEnter {
    [super onEnter];
    [[CCDirector sharedDirector] presentScene:[[MainScene alloc] init]];
}

@end
