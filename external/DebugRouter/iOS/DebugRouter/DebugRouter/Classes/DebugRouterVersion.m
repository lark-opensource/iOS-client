#import "DebugRouterVersion.h"

@implementation DebugRouterVersion

+ (NSString *)versionString {
// source build will define DebugRouter_POD_VERSION
// binary build will replace string by .rock-package.yml
#ifndef DebugRouter_POD_VERSION
#define DebugRouter_POD_VERSION @"9999_2.0.0"
#endif
  return [DebugRouter_POD_VERSION substringFromIndex:5];
}
@end
