//
//  ADFeelGoodConfig+Private.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/14.
//

#import "ADFeelGoodConfig+Private.h"
#import "ADFeelGoodParamKeysDefine.h"
#import "ADFeelGoodURLConfig.h"
#import "ADFGUtils.h"
#import "UIDevice+ADFGAdditions.h"

@implementation ADFeelGoodConfig (Private)

- (void)checkNunNull
{
    NSAssert(self.appKey.length > 0, @"appKey 不能为空");
    NSAssert(self.did.length > 0, @"did 不能为空");
    NSAssert(self.channel.length > 0, @"channel 不能为空");
    if (self.language.length == 0) {
        self.language = [[NSLocale currentLocale] objectForKey:NSLocaleCollatorIdentifier];
    }
}

- (NSMutableDictionary *)getBaseUserInfo
{
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    [user setObject:self.uName?:@"" forKey:ADFGUserName];
    [user setObject:self.uid?:@"" forKey:ADFGUserID];
    [user setObject:self.did?:@"" forKey:ADFGDeviceID];
    // os_name
    [user setObject:@"iOS" forKey:ADFGOSName];
    // app_version
    NSString *versionName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [user setObject:versionName forKey:ADFGAppVersion];
    // os_version
    NSString *strSysVersion = [[UIDevice currentDevice] systemVersion]; 
    [user setObject:strSysVersion forKey:ADFGOSVersion];
    // device_name
    NSString *deviceName = [UIDevice adfg_devidePlatformString];
    [user setObject:deviceName forKey:ADFGDeviceName];
    return user;
}

/// 获取请求通参
/// @param eventID 用户行为事件标识
/// @param extraUserInfo 自定义用户标识，请求时添加到user字典中
- (NSMutableDictionary *)checkQuestionParamsWithEventID:(NSString *)eventID extraUserInfo:(NSDictionary *)extraUserInfo
{
    [self checkNunNull];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.appKey?:@"" forKey:ADFGAppToken];
    [params setObject:self.channel?:@"" forKey:ADFGChannel];
    [params setObject:self.language?:@"zh_CN" forKey:ADFGLanguage];
    [params setObject:@"iOS" forKey:ADFGPlatform];
    [params setObject:self.deviceType?:@"mobile" forKey:ADFGDeviceType];
    //user信息
    NSMutableDictionary *user = [self getBaseUserInfo];
    // extraParams为业务方设置的用户标志, 通过 user 字段透传给Feelgood Report API
    [user addEntriesFromDictionary:self.userInfo];
    [user addEntriesFromDictionary:extraUserInfo];
    
    //events
    if (eventID.length) {
        //eventID信息
        NSMutableDictionary *events = [NSMutableDictionary dictionary];
        [events setObject:@(1) forKey:ADFGEventsCnt];
        [events setObject:@(1) forKey:ADFGEventsCustom];
        [events setObject:eventID?:@"" forKey:ADFGEventsType];
        NSMutableArray *array = [NSMutableArray arrayWithObject:events];
        [params setObject:array forKey:ADFGEvents];
    }
    
    [params setObject:user forKey:ADFGUser];
    [params setObject:@(100) forKey:ADFGSurveyType];
    [params setObject:@(2) forKey:ADFGClientEnv];
    
    return params;
}

- (NSMutableDictionary *)webviewParamsWithTaskID:(NSString *)taskID taskSetting:(NSDictionary *)taskSetting extraUserInfo:(NSDictionary *)extraUserInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params adfg_setString:self.appKey?:@"" forKey:ADFGAppKey];
    [params adfg_setString:self.channel?:@"" forKey:ADFGChannel];
    [params adfg_setString:self.language?:@"zh_CN" forKey:ADFGLanguage];
    [params adfg_setString:@"iOS" forKey:ADFGPlatform];
    [params adfg_setString:self.deviceType?:@"mobile" forKey:ADFGDeviceType];
    [params adfg_setString:taskID?:@"" forKey:ADFGTaskID];
    [params adfg_setObjectSafe:taskSetting?:@{} forKey:@"taskSetting"];
    // user信息
    NSMutableDictionary *user = [self getBaseUserInfo];
    // extraParams为业务方设置的用户标志, 通过 user 字段透传给Feelgood Report API
    [user addEntriesFromDictionary:self.userInfo];
    [user addEntriesFromDictionary:extraUserInfo];
    
    [params setObject:user forKey:ADFGUser];
    return params;
}

- (NSString *)headerOrigin {
    return [ADFeelGoodURLConfig headerOriginURLWithChannel:self.channel];
}


@end
