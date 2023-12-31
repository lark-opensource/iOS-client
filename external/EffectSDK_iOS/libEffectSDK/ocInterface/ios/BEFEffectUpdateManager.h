#import <Foundation/Foundation.h>

@interface BEFEffectUpdateManager : NSObject
{
}

+ (void) init:(BOOL)isDebugMode;
+ (void) initRootDir;
+ (BOOL) isInited;
+ (const char*)getRootDir;
+ (void) clearCache;
@end
