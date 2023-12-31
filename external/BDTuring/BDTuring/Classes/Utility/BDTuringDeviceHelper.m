//
//  BDTuringDeviceHelper.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "BDTuringDeviceHelper.h"
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <sys/xattr.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/sysctl.h>
#import "sys/utsname.h"

@implementation BDTuringDeviceHelper

+ (NSString *)deviceBrand {
    static NSString *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *machineModel = [self deviceModel];
        if ([machineModel hasPrefix:@"iPod"]) {
            result = @"iPod";
        } else if ([machineModel hasPrefix:@"iPad"]) {
            result = @"iPad";
        } else {
            result = @"iPhone";
        }
    });

    return result;
}

+ (NSString *)deviceModel {
    static dispatch_once_t onceToken;
    static NSString *model;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = (char *)malloc(size);
        if (machine){
            sysctlbyname("hw.machine", machine, &size, NULL, 0);
            model = [NSString stringWithUTF8String:machine];
            free(machine);
        }
        
        if ([model containsString:@"i386"] || [model containsString:@"x86_64"] || [model containsString:@"arm64"]) {
            model = [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_MODEL_IDENTIFIER"];
        }
    });

    return model;
}
#if 0
+ (NSString *)firstSupportLanguage {
    static NSString *lang = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *all = [self supportLanguage];
        NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
        
        [preferredLanguages enumerateObjectsUsingBlock:^(NSString *localeIdentifier, NSUInteger idx, BOOL *stop) {
            NSDictionary<NSString *, NSString *> *languageDic = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
            NSString *language = [[languageDic objectForKey:NSLocaleLanguageCode] lowercaseString];
            
            if ([all containsObject:language]) {
                if ([language isEqualToString:@"zh"] && languageDic.count > 1) {
                    NSString *script = [languageDic objectForKey:NSLocaleScriptCode];
                    lang = [NSString stringWithFormat:@"%@-%@",language, script];
                } else {
                    lang = [language mutableCopy];
                }

                *stop = YES;
            }
        }];
    });

    return lang;
}

+ (NSArray<NSString *> *)supportLanguage {
    static NSArray<NSString *> *supportLanguage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportLanguage = @[@"id",
                            @"ms",
                            @"jv",
                            @"ceb",
                            @"cs",
                            @"de",
                            @"en",
                            @"es",
                            @"fil",
                            @"fr",
                            @"it",
                            @"hu",
                            @"nl",
                            @"pl",
                            @"pt",
                            @"ro",
                            @"sv",
                            @"vi",
                            @"tr",
                            @"el",
                            @"ru",
                            @"uk",
                            @"mr",
                            @"hl",
                            @"bn",
                            @"pa",
                            @"qu",
                            @"or",
                            @"ta",
                            @"te",
                            @"kn",
                            @"ml",
                            @"th",
                            @"my",
                            @"ko",
                            @"ja",
                            @"ar",
                            @"zh",
                            @"zh-Hant",
                            @"zh-Hans",
                            ];

    });

    return supportLanguage;
}
#endif

+ (NSString *)systemVersion {
    static NSString *systemVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
        systemVersion = [NSString stringWithFormat:@"%zd.%zd",version.majorVersion,version.minorVersion];
        if (version.patchVersion > 0) {
            systemVersion = [systemVersion stringByAppendingFormat:@".%zd",version.patchVersion];
        }
    });
    
    return systemVersion;
}

+ (CGSize)resolution {
    static CGSize resolution = {0,0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        float scale = [[UIScreen mainScreen] scale];
        resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    });
    
    return resolution;
}

+ (NSString *)resolutionString {
    static NSString *resolutionString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGSize resolution = [self resolution];
        NSInteger width = resolution.width;
        NSInteger height = resolution.height;
        resolutionString = [NSString stringWithFormat:@"%zd*%zd", width, height];
    });
    
    return resolutionString;
}

+ (NSString *)localeIdentifier {
    return [[NSLocale currentLocale] localeIdentifier];
}

@end
