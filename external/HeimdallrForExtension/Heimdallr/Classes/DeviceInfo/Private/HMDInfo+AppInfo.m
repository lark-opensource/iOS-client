//
//  HMDInfo+AppInfo.m
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo+AppInfo.h"
#import "UIApplication+HMDUtility.h"

@implementation HMDInfo (AppInfo)
- (NSString *)appDisplayName {
    static NSString *appName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        if (!appName) {
          appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        }
    });
    return appName;
}

- (nonnull NSString *)version {
    static NSString *version = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [NSString stringWithFormat:@"%@(%@)", [self shortVersion], [self buildVersion]];
    });
    return version;
}

- (NSString *)shortVersion {
    static NSString *shortVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    });
    return shortVersion;
}

- (NSString *)bundleIdentifier {
    static NSString *bundleIdentifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    });
    return bundleIdentifier;
}

- (NSString *)buildVersion {
    static NSString *buildVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    });
    return buildVersion;
}

- (NSString *)commitID {
    static NSString *commitID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Heimdallr" ofType:@"plist"];
        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        commitID = [data objectForKey:@"commit"];
    });
    
    return commitID ?: @"";
}

- (NSString *)emUUID {
    static NSString *emUUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Heimdallr" ofType:@"plist"];
        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        emUUID = [data objectForKey:@"emuuid"];
    });
    
    return emUUID ?: @"";
}

- (NSString *)sdkVersion {
    return kHeimdallrPodVersion;
}

- (NSInteger)sdkVersionCode {
    static NSInteger versionCode = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *versionString = [self sdkVersion];
        versionCode = [self transformToIntegerFromString:versionString];
    });
    
    return versionCode;
}

/**
 将sdk版本号由字符串转换为整数

 @param versionString 形如 13_0.4.0/13_0.4.0.1-bugfix/13_0.4.0-rc.0/0.4.0，形式是打包产品线appid/三位或者四位版本号（可能有rc，alpha，bugfix等后缀）
 @return 一个整数，方便直接比较大小，如40000
 */
- (NSInteger)transformToIntegerFromString:(NSString *)versionString {
    NSRange prefixRange = [versionString rangeOfString:@"_"];
    if(prefixRange.location != NSNotFound){
        versionString = [versionString substringFromIndex:(prefixRange.location + prefixRange.length)];
    }
    
    NSRange suffixRange = [versionString rangeOfString:@"-"];
    if(suffixRange.location != NSNotFound){
        versionString = [versionString substringToIndex:suffixRange.location];
    }
    
    NSArray<NSString *> *digits = [versionString componentsSeparatedByString:@"."];
    
    if (digits.count > 3) {
        digits = [digits subarrayWithRange:NSMakeRange(0, 3)];
    }
    
    __block NSInteger versionCode = 0;
    NSInteger total = digits.count;
    
    NSAssert(total == 3, @"The string format of version number must have 3 parts!");
    
    [digits enumerateObjectsUsingBlock:^(NSString * _Nonnull digit, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([digit stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].length == 0, @"The string format of version number contains non-numeric characters which isn't as expected.");
        NSAssert([digit integerValue] < 100, @"Any part of the version number must be the units digit.");
        
        versionCode += [digit integerValue] * (NSInteger)pow(100,(total-idx-1));
    }];
    
    return versionCode;
}

@end
