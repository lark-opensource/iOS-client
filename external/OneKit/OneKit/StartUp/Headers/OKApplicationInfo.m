//
//  OKApplicationInfo.m
//  OKStartUp
//
//  Created by bob on 2020/1/14.
//

#import "OKApplicationInfo.h"
#import "OKDevice.h"
#import "NSDictionary+OK.h"

NSString *kOKInfoFileResourceName = @"onekit-config";

@interface OKApplicationInfo ()

@end

@implementation OKApplicationInfo

+ (instancetype)sharedInstance {
    static OKApplicationInfo *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.appID = self.serviceInfo[@"project_info"][@"app_id"];
        self.accessKey = self.serviceInfo[@"project_info"][@"ak"];
        self.secretKey = self.serviceInfo[@"project_info"][@"sk"];
        self.isInhouseApp = [self.serviceInfo[@"project_info"][@"is_inhouse_app"] isEqualToValue: [NSNumber numberWithBool:YES]];
        
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        self.appName = [infoDictionary ok_stringValueForKey:@"CFBundleName"];
        self.appDisplayName = [infoDictionary ok_stringValueForKey:@"CFBundleDisplayName"];
        self.channel = @"App Store";
        self.appVersion = [infoDictionary ok_stringValueForKey:@"CFBundleShortVersionString"];
        self.buildVersion = [infoDictionary ok_stringValueForKey:@"CFBundleVersion"];
        self.buildVersionCode =  [self.buildVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
        self.bundleIdentifier = [infoDictionary ok_stringValueForKey:@"CFBundleVersion"];
        self.deviceModel = [OKDevice machineModel];
        self.devicePlatform = [OKDevice platformName];
        self.systemVersion = [OKDevice systemVersion];
        self.sharingKeyChainGroup = nil;
    }
    
    return self;
}

/// 一般为APP配置文件的内容。若用户从接口传入，则为用户传入的内容
- (NSDictionary *)serviceInfo {
    if (!_serviceInfo) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *plistPath = [NSBundle.mainBundle pathForResource:kOKInfoFileResourceName ofType:@"plist"];
            if (plistPath) {
                NSDictionary *plistDic = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
                _serviceInfo = [OKApplicationInfo trimDic:plistDic];
            }
        });
    }
    return _serviceInfo;
}

+ (NSDictionary *)trimDic:(NSDictionary *)input {
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (id key in input.allKeys) {
        result[[self trimValue:key]] = [self trimValue:input[key]];
    }
    return result.copy;
}

+ (NSArray *)trimArr:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray new];
    for (id singleValue in array) {
        [result addObject:[self trimValue:singleValue]];
    }
    return result.copy;
}

+ (NSString *)trimStr:(NSString *)input {
    return [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (id)trimValue:(id)input {
    if ([input isKindOfClass:NSArray.class]) {
        return [self trimArr:input];
    } else if ([input isKindOfClass:NSDictionary.class]) {
        return [self trimDic:input];
    } else if ([input isKindOfClass: NSString.class]) {
        return [self trimStr:input];
    } else {
        return input;
    }
}

@end
