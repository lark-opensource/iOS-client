//
//  CJPayEnvManager.m
//  CJPay
//
//  Created by 王新华 on 2019/1/6.
//

#import "CJPayEnvManager.h"
#import "CJPayTouchIdManager.h"
#import "CJPaySDKMacro.h"

@implementation CJPayEnvManager

+ (instancetype)shared {
    static CJPayEnvManager *env;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        env = [CJPayEnvManager new];
    });
    return env;
}

- (BOOL)isSafeEnv {
    return ![self isJailBreak];
}

- (BOOL)isJailBreak {
    return [self hasJailBreakFiles] || [self canOpenCydia] || [self canGetAllAppName];
}

- (BOOL)hasJailBreakFiles {
    NSArray *jailbreak_tool_paths = @[
                                      @"/Applications/Cydia.app",
                                      @"/Library/MobileSubstrate/MobileSubstrate.dylib",
                                      @"/bin/bash",
                                      @"/usr/sbin/sshd",
                                      @"/etc/apt"
                                      ];
    
    for (int i=0; i<jailbreak_tool_paths.count; i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:jailbreak_tool_paths[i]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canOpenCydia{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) {
        return YES;
    }
    return NO;
}

- (BOOL)canGetAllAppName{
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"User/Applications/"]) {
        NSArray *appList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"User/Applications/" error:nil];
        return appList.count > 0;
    }
    return NO;
}

- (NSDictionary *)appendParamTo:(NSDictionary *)dic {
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSData *bioParamData = [CJPayTouchIdManager currentOriTouchIdData];
    if (bioParamData && bioParamData.length > 0) {
        [param cj_setObject:CJString([bioParamData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]) forKey:@"biometric_params"];
    }
    BOOL isSafe = (BOOL)[self isSafeEnv];
    [param cj_setObject:(isSafe) ? @"2" : @"1" forKey:@"is_jailbreak"];
    return [param copy];
}

@end
