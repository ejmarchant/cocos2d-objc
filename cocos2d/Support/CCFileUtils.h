
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface CCFileUtils : NSObject

+(instancetype)sharedFileUtils;

// Preferred method.
-(NSString*)fullPathForFilename:(NSString*)filename;

// Deprecated methods.
-(NSString*)fullPathForFilename:(NSString*)filename contentScale:(CGFloat*)contentScale;
-(NSString*)standarizePath:(NSString*)path;
-(NSString*)fullPathForFilenameIgnoringResolutions:(NSString*)filename;
-(NSString*)fullPathFromRelativePathIgnoringResolutions:(NSString*)relPath;
-(NSArray*)fullPathsOfFileNameInAllSearchPaths:(NSString*)filename;
-(void)purgeCachedEntries;
-(void)buildSearchResolutionsOrder;
-(NSDictionary*)filenameLookup;

@end


#ifdef __cplusplus
extern "C" {
#endif
    
    /**
     *  Loads a file into memory.
     *  It is the callers responsibility to release the allocated buffer.
     *
     *  @return The size of the allocated buffer.
     *  @warning Avoid using this method in new code. See class *Overview*.
     */
    NSInteger ccLoadFileIntoMemory(const char *filename, unsigned char **out);
    
#ifdef __cplusplus
}
#endif
