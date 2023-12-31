//
//  TouTiaoPushSDK.m
//  TouTiaoPushSDKDemo
//
//  Created by wangdi on 2017/7/30.
//  Copyright © 2017年 wangdi. All rights reserved.
//

#import "TouTiaoPushSDK.h"
#import "PushSDKTracker.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>

@import UserNotifications;

@implementation TTBaseRequestParam

+ (instancetype)requestParam
{
    TTBaseRequestParam *requestParam = [[self alloc] init];
    return requestParam;
}

- (instancetype)init
{
    if(self = [super init]) {

        _appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppName"];
        _aId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSAppID"];
        _host = @"https://ib.snssdk.com";
    }
    return self;
}

- (NSString *)hostValue {
    if ([_host hasPrefix:@"http://"] || [_host hasPrefix:@"https://"]) {
        return _host;
    }
    return [[NSString alloc] initWithFormat:@"https://%@", _host];
}

@end

@implementation TTChannelRequestParam

- (instancetype)init
{
    if(self = [super init]) {
        _pushSDK = @"[13]";
        _package = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        _versionCode = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _osVersion = [[UIDevice currentDevice] systemVersion];
        _os = @"iOS";
        _channel = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"];
    }
    return self;
}

@end

@implementation TTUploadTokenRequestParam

@end

@implementation TTUploadSwitchRequestParam

@end

@implementation TTBaseResponse

@end

@interface TouTiaoPushSDKJSONResponseSerializer : TTHTTPJSONResponseSerializerBase

@end

@implementation TouTiaoPushSDKJSONResponseSerializer

- (instancetype)init
{
    if ((self = [super init])) {
        self.acceptableContentTypes = [NSSet setWithObjects:
                                       @"application/json",
                                       @"text/json",
                                       @"text/javascript",
                                       @"application/octet-stream",
                                       @"text/html",
                                       @"text/plain",
                                       nil];
    }
    return self;
}

+ (NSObject<TTJSONResponseSerializerProtocol> *)serializer
{
    return [[self alloc] init];
}

@end

@implementation TouTiaoPushSDK

static dispatch_queue_t request_operation_queue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

+ (void)sendRequestWithParam:(TTBaseRequestParam *)requestParam completionHandler:(void (^)(TTBaseResponse *))completionHandler {
    dispatch_async(request_operation_queue(), ^{
        [self sendRequestInQueueWithParam:requestParam completionHandler:completionHandler];
    });
}

+ (void)sendRequestInQueueWithParam:(TTBaseRequestParam *)requestParam completionHandler:(void (^)(TTBaseResponse *))completionHandler
{
    NSString *url = [self _requestUrlWithRequest:requestParam];
    NSDictionary *param = [self _requestParamWithRequest:requestParam];
    [[TTNetworkManager shareInstance] requestForJSONWithURL:url params:param method:@"POST" needCommonParams:YES requestSerializer:[TTDefaultHTTPRequestSerializer class] responseSerializer:[TouTiaoPushSDKJSONResponseSerializer class] autoResume:YES callback:^(NSError *error, id jsonObj) {
        TTBaseResponse *response = [[TTBaseResponse alloc] init];
        NSString *message = [jsonObj valueForKey:@"message"];
        if([message isEqualToString:@"success"] && !error) {
            response.success = YES;
        } else {
            response.success = NO;
            if(!error) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                [userInfo setValue:message forKey:NSLocalizedFailureReasonErrorKey];
                error = [NSError errorWithDomain:url code:-1020 userInfo:userInfo];
            }
        }
        response.error = error;
        response.jsonObj = jsonObj;
        if(completionHandler) {
            completionHandler(response);
        }
    }];
}


+ (void)trackerWithRuleId:(NSString *)ruleId clickPosition:(NSString *)clickPosition postBack:(NSString *)postBack
{
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:ruleId forKey:@"rule_id"];
    [param setValue:clickPosition forKey:@"click_position"];
    [param setValue:postBack forKey:@"post_back"];
    [[PushSDKTrackerProvider shared].tracker event:@"push_click" params:param];
}

+ (NSString *)_requestUrlWithRequest:(TTBaseRequestParam *)request
{
    if([request isKindOfClass:[TTChannelRequestParam class]]) {
        return [self _getChannelUrlWithRequest:(TTChannelRequestParam *)request];
    } else if([request isKindOfClass:[TTUploadTokenRequestParam class]]) {
        return [self _getUploadTokenUrlWithRequest:(TTUploadTokenRequestParam *)request];
    } else if([request isKindOfClass:[TTUploadSwitchRequestParam class]]) {
        return [self _getUploadSwitchUrlWithRequest:(TTUploadSwitchRequestParam *)request];
    }
    return nil;
}

+ (NSDictionary *)_requestParamWithRequest:(TTBaseRequestParam *)request
{
    if([request isKindOfClass:[TTChannelRequestParam class]]) {
        return [self _getChannelParamWithRequest:(TTChannelRequestParam *)request];
    } else if([request isKindOfClass:[TTUploadTokenRequestParam class]]) {
        return [self _getUploadTokenParamWithRequest:(TTUploadTokenRequestParam *)request];
    } else if([request isKindOfClass:[TTUploadSwitchRequestParam class]]) {
        return [self _getUploadSwitchParamWithRequest:(TTUploadSwitchRequestParam *)request];
    }
    return nil;
}

+ (NSMutableDictionary<NSString *,NSString *> *)_getCommonParamDictWithRequest:(TTBaseRequestParam *)request
{
    NSMutableDictionary<NSString *,NSString *> *paramDict = [NSMutableDictionary dictionary];
    [paramDict setValue:request.aId forKey:@"aid"];
    if(request.deviceId.length <= 0) {
        [paramDict setValue: [[PushSDKTrackerProvider shared].tracker deviceID] forKey:@"device_id"];
    } else {
        [paramDict setValue:request.deviceId forKey:@"device_id"];
    }
    if(request.installId.length <= 0) {
        [paramDict setValue: [[PushSDKTrackerProvider shared].tracker installID] forKey:@"install_id"];
    } else {
        [paramDict setValue:request.installId forKey:@"install_id"];
    }
    [paramDict setValue:request.appName forKey:@"app_name"];

    if(request.deviceLoginId.length > 0) {
        [paramDict setValue: request.deviceLoginId forKey:@"device_login_id"];
    }

    return paramDict;
}

+ (NSString *)_getSystemPushStatus
{
    __block UNNotificationSettings *currentSettings;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        currentSettings = settings;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    switch (currentSettings.authorizationStatus) {
        case UNAuthorizationStatusAuthorized:
        case UNAuthorizationStatusProvisional:
            return @"1";
        case UNAuthorizationStatusDenied:
        case UNAuthorizationStatusNotDetermined:
            return @"0";

        // 140000 equal to __IPHONE_14_0, but __IPHONE_14_0 is definded in iOS14 runtime.
        // `UNAuthorizationStatusEphemeral` only available to app clips.
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
        case UNAuthorizationStatusEphemeral:
            return @"1";
        #endif
    }
}

+ (NSString *)_getChannelUrlWithRequest:(TTChannelRequestParam *)request
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/cloudpush/update_sender/",[request hostValue]];
    return urlStr;
}

+ (NSString *)_getUploadTokenUrlWithRequest:(TTUploadTokenRequestParam *)request
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/service/1/update_token/",[request hostValue]];
    return urlStr;
}

+ (NSString *)_getUploadSwitchUrlWithRequest:(TTUploadSwitchRequestParam *)request
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/service/1/app_notice_status/",[request hostValue]];
    return urlStr;
}

+ (NSDictionary *)_getChannelParamWithRequest:(TTChannelRequestParam *)request
{
    NSMutableDictionary<NSString *,NSString *> *paramDict = [self _getCommonParamDictWithRequest:request];
    [paramDict setValue:request.channel forKey:@"channel"];
    [paramDict setValue:request.pushSDK forKey:@"push_sdk"];
    [paramDict setValue:request.versionCode forKey:@"version_code"];
    [paramDict setValue:request.osVersion forKey:@"os_version"];
    [paramDict setValue:request.package forKey:@"package"];
    [paramDict setValue:request.os forKey:@"os"];
    [paramDict setValue:request.notice forKey:@"notice"];
    [paramDict setValue:[self _getSystemPushStatus] forKey:@"system_notify_status"];
    return paramDict;
}

+ (NSDictionary *)_getUploadTokenParamWithRequest:(TTUploadTokenRequestParam *)request
{
    NSMutableDictionary<NSString *,NSString *> *paramDict = [self _getCommonParamDictWithRequest:request];
    [paramDict setValue:request.token forKey:@"token"];
    return paramDict;
}

+ (NSDictionary *)_getUploadSwitchParamWithRequest:(TTUploadSwitchRequestParam *)request
{
    NSMutableDictionary<NSString *,NSString *> *paramDict = [self _getCommonParamDictWithRequest:request];
    [paramDict setValue:request.notice forKey:@"notice"];
    [paramDict setValue:[self _getSystemPushStatus] forKey:@"system_notify_status"];
    return paramDict;
}

@end
