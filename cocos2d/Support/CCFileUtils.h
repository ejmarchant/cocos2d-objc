
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCFileUtils : NSObject

@property(nonatomic,strong) NSArray<NSString*> *searchDirectories;

+(instancetype)sharedFileUtils;

// Preferred method.
-(nullable NSString*)fullPathForFilename:(NSString*)filename;

// Deprecated methods.
-(nullable NSString*)fullPathForFilename:(NSString*)filename contentScale:(nullable CGFloat*)contentScale;
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
    NSInteger ccLoadFileIntoMemory(const char * _Nonnull filename, unsigned char * _Nonnull * _Nonnull out);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
