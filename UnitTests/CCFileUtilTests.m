//
//  CCFileUtilTests
//
//  Created by Andy Korth on December 6th, 2013.
//
//

#import <XCTest/XCTest.h>
#import "cocos2d.h"
#import "CCUnitTestAssertions.h"


@interface CCFileUtilTests : XCTestCase

@end

@implementation CCFileUtilTests

- (void)setUp
{
    [super setUp];
    CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
    sharedFileUtils.searchDirectories = @[];
}

-(void)testFullPathForFilenameMissingFile
{
	CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];

	NSString *path = [sharedFileUtils fullPathForFilename:@"file that does not exist"];
	
	XCTAssertTrue(path == nil, @"");
	
	// File does not exist in this directory
	path = [sharedFileUtils fullPathForFilename:@"powered.png"];
	XCTAssertTrue(path == nil, @"");
}

// XCode Unit tests look inside the target's test application bundle - not the unit test app bundle, but the "cocos2d-tests-ios.app" bundle.
-(void)testFullPathForFilename
{
    CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
    
	NSString *path = [sharedFileUtils fullPathForFilename:@"Images/powered.png"];
	NSLog(@"Path: %@", path);
	XCTAssertTrue(path != nil, @"");
}

@end
