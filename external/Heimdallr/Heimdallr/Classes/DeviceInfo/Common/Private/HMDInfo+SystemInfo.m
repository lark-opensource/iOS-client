//
//  HMDInfo+SystemInfo.m
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo+SystemInfo.h"
#include <sys/sysctl.h>
#include "HMDDeviceTool.h"
#import "HeimdallrUtilities.h"
@implementation HMDInfo (SystemInfo)

- (BOOL)isLowPowerModeEnabled {
    if (@available(iOS 9.0, *)) {
        return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
    } else {
        return NO;
    }
}

- (NSString *)systemName {
    return [HeimdallrUtilities systemName];
}

- (NSString *)systemVersion {
    return [HeimdallrUtilities systemVersion];
}

- (NSString *)executablePath {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:self.executableName];
}

- (NSString *)executableName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
}

- (NSString *)osVersion {
    NSString *osVersion = nil;
    
    NSString *version = [self stringSysctl:@"kern.osversion"];
    if (version) {
        return version;
    }
    return osVersion;
}
/** Get a sysctl value as a null terminated string.
 *
 * @param name The sysctl name.
 *
 * @return The result of the sysctl call.
 */
- (NSString *)stringSysctl:(NSString *)name
{
  int size = (int)hmd_kssysctl_stringForName([name UTF8String], NULL, 0);
  if(size <= 0)
  {
    return nil;
  }
  
  char* value = malloc((size_t)size);
  if(hmd_kssysctl_stringForName([name UTF8String], value, size) <= 0)
  {
    free(value);
    return nil;
  }
  NSString *valueString = [NSString stringWithUTF8String:value];

  free(value);

  return valueString;
}
- (int)processID {
  return [NSProcessInfo processInfo].processIdentifier;
}

- (NSString *)processName {
  return  [NSProcessInfo processInfo].processName;
}

- (NSString *)platform {
    static NSString *pl = nil;
    if (!pl) {
        pl = [[self class] getSysInfoByName:"hw.machine"];
    }
    return pl;
}

+ (NSString *)getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    
    if (nil == results || 0 == results.length) {
        results = @"iPhoneUnknown";
    }
    return results;
}

@end
