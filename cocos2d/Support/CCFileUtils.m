
#import "CCFileUtils.h"
#import "ccMacros.h"


@implementation CCFileUtils

+(instancetype)sharedFileUtils {
    static CCFileUtils *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CCFileUtils alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init {
    self = [super init];
    return self;
}

-(NSString*)fullPathForFilename:(NSString*)filename {
    return [self fullPathForFilename:filename contentScale:NULL];
}

-(NSString*)fullPathForFilename:(NSString*)filename contentScale:(CGFloat*)contentScale {
    if (contentScale != NULL) {
        *contentScale = 1.0;
    }
    // Check if file exists (full path provided), otherwise use bundle.
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        return [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    }
    return filename;
}

-(NSString*)standarizePath:(NSString*)path {
    // TODO: Remove suffixes?
    return [path stringByStandardizingPath];
}

-(NSString*)fullPathForFilenameIgnoringResolutions:(NSString*)filename {
    return filename;
}

-(NSString*)fullPathFromRelativePathIgnoringResolutions:(NSString*)relPath {
    return relPath;
}

-(NSArray*)fullPathsOfFileNameInAllSearchPaths:(NSString*)filename {
    return @[filename];
}

-(void)purgeCachedEntries {
}

-(void)buildSearchResolutionsOrder {
}

-(NSDictionary*)filenameLookup {
    return @{};
}

@end


NSInteger ccLoadFileIntoMemory(const char *filename, unsigned char **out)
{
    NSCAssert( out, @"ccLoadFileIntoMemory: invalid 'out' parameter");
    NSCAssert( &*out, @"ccLoadFileIntoMemory: invalid 'out' parameter");
    
    size_t size = 0;
    FILE *f = fopen(filename, "rb");
    if( !f ) {
        *out = NULL;
        return -1;
    }
    
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    *out = malloc(size);
    size_t read = fread(*out, 1, size, f);
    if( read != size ) {
        free(*out);
        *out = NULL;
        return -1;
    }
    
    fclose(f);
    
    return size;
}
