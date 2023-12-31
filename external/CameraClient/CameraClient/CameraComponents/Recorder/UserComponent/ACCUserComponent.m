//
//  AWEPropUserComponent.m
//  AWEStudio-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/15.
//

#import "ACCUserComponent.h"

#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CameraClient/ACCEffectMessageDownloader.h>
#import <CameraClient/ACCUserViewModel.h>

#import <CreativeKit/ACCMacros.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreativeKit/ACCCacheProtocol.h>

static NSString * const kInterfaceKey = @"interface";
static NSString * const kStatusKey = @"status";

static NSString * const kInterfaceValueGetCookie = @"cookie";
static NSString * const kInterfaceValueSendCookie = @"cookie";
static NSString * const kInterfaceValueProfile = @"NICK";
// 抽帧上传权限
static NSString * const kInterfaceValuePrivacy = @"privacy";
static NSString * const kPrivacyTypeUploadImage = @"uploadImage";
static NSString * const kCacheKeyPrivacy = @"kCacheKeyPrivacy";

static NSErrorDomain const KDownloadErrorDomaon = @"AWEPropUserComponentErrorDomain";
static const NSInteger kUserinfoMsgId = 0x29;


@interface ACCUserComponent () <ACCEffectEvent>

@property (nonatomic, strong) id<ACCCameraService> cameraService;

@property (nonatomic, strong) id<ACCNetworkReachabilityProtocol> reachabilityManager;

@property (nonatomic, strong) ACCUserViewModel *viewModel;

@end

@implementation ACCUserComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, reachabilityManager, ACCNetworkReachabilityProtocol)

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}


- (void)componentDidMount
{
    self.viewModel = [self.modelFactory createViewModel:ACCUserViewModel.class];
    [self.cameraService.message addSubscriber:self];
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message
{
    AWELogToolInfo(AWELogToolTagNone, @"AWEPropUserComponent receive message type=%zi|msgId=%zi", message.type, message.msgId);
    if (message.type == IESMMEffectMsgOther) {
        switch (message.msgId) {
            case kUserinfoMsgId:
                [self handleArg2:message.arg2 arg3:message.arg3];
                break;
                
            default:
                break;
        }
    }
}

- (void)handleArg2:(NSInteger)arg2 arg3:(NSString *)arg3
{
    NSData *data = [arg3 dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSAssert(!error, @"json serialization failed, error=%@", error);
        if (!error && [dict isKindOfClass:NSDictionary.class]) {
            [self handleJson:dict taskId:arg2];
        } else {
            AWELogToolError(AWELogToolTagNone, @"poi component JSON serialization failed, error=%@", error);
        }
    }
}

- (void)handleJson:(NSDictionary *)json taskId:(NSInteger)taskId
{
    NSString *interface = [json acc_stringValueForKey:kInterfaceKey];
    if ([interface isEqualToString:kInterfaceValueGetCookie]) {
        NSDictionary *body = [json  acc_dictionaryValueForKey:@"body"];
        [self handleCookieWithEffectBody:body taskId:taskId];
    } else if ([interface isEqualToString:kInterfaceValueProfile]) {
        [self handleUserProfileWithTaskId:taskId];
    } else if ([interface isEqualToString:kInterfaceValuePrivacy]) {
        NSString *type = [json acc_stringValueForKey:@"type"];
        if ([type isEqualToString:kPrivacyTypeUploadImage]) {
            [self handlePrivacyWithTaskId:taskId];
        }
    }
}

#pragma mark - Cookie

- (void)handleCookieWithEffectBody:(NSDictionary *)dict taskId:(NSInteger)taskId
{
    NSString *urlString = @"";
    NSString *cookieString = @"";
    
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    response[kInterfaceKey] = kInterfaceValueSendCookie;
    response[kStatusKey] = @(0);
    NSMutableDictionary *sendBody = [NSMutableDictionary dictionary];
    sendBody[@"url"] = urlString;
    sendBody[@"cookie"] = cookieString;
    response[@"body"] = sendBody;
    
    if ([dict isKindOfClass:NSDictionary.class] && [dict[@"url"] isKindOfClass:NSString.class]) {
        urlString = [dict acc_stringValueForKey:@"url"];
    } else {
        NSAssert(NO, @"effect body is invalid, effectBody=%@", dict);
    }
    
    NSAssert(urlString.length > 0, @"cookie urlString is empty!!");
    if (urlString.length == 0) {
        AWELogToolError(AWELogToolTagNone, @"cookie urlString is empty!!");
        response[kStatusKey] = @1;
        // send error when urlString is empty
        [self sendMessageToEffect:response taskId:taskId];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSAssert(url, @"cookie url is nil!!");
    if (url == nil) {
        // send error when url is nil
        [self sendMessageToEffect:response taskId:taskId];
        return;
    }
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:url];
    for (NSHTTPCookie *cookie in cookies) {
        cookieString = [cookieString stringByAppendingFormat:@"%@=%@; ", cookie.name, cookie.value];
    }
    cookieString = [cookieString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (cookieString.length > 0) {
        // remove the last ';' character
        cookieString = [cookieString substringToIndex:cookieString.length-1];
    }
    
    sendBody[@"url"] = urlString;
    sendBody[@"cookie"] = cookieString;
    [self sendMessageToEffect:response taskId:taskId];
}

#pragma mark - Profile

- (void)handleUserProfileWithTaskId:(NSInteger)taskId
{
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    response[kInterfaceKey] = kInterfaceValueProfile;
    response[kStatusKey] = @0;
    NSMutableDictionary *sendBody = [NSMutableDictionary dictionary];
    response[@"body"] = sendBody;
    sendBody[@"nickname"] = @"";
    sendBody[@"avatar_path"] = @"";
    
    let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
    id<ACCUserModelProtocol> user = userService.currentLoginUserModel;
    sendBody[@"nickname"] = user.socialName ?: @"";
    
    @weakify(self);
    [self imageCachePathWithUrl:user.avatarThumb.URLList completion:^(NSString *cachePath, NSError *error) {
        @strongify(self);
        sendBody[@"avatar_path"] = cachePath ?: @"";
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"image cache path error=%@", error);
            response[kStatusKey] = @1;
        }
        [self sendMessageToEffect:response taskId:taskId];
    }];
}

- (void)imageCachePathWithUrl:(NSArray<NSString *> *)urlList
                   completion:(void(^)(NSString *filePath, NSError * error))completion
{
    
    [[ACCEffectMessageDownloader sharedDownloader] downloadWithUrlList:urlList
                                                             needUpzip:NO
                                                            completion:^(NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"requstImageWithUrlList failed, error=%@", error);
        }
        
        if (completion) {
            completion(filePath.path, error);
        }
    }];
}

#pragma mark - Privacy

- (void)handlePrivacyWithTaskId:(NSInteger)taskId
{
    @weakify(self);
    void(^privacyBlock)(BOOL) = ^(BOOL privacy) {
        @strongify(self);
        NSInteger permission = privacy ? 0 : 1;
        NSDictionary *sendBody = @{
            kInterfaceKey : kInterfaceValuePrivacy,
            @"permission" : @(permission),
        };
        
        [self sendMessageToEffect:sendBody taskId:taskId];
    };
    
    BOOL allowPrivay = [ACCCache() boolForKey:kCacheKeyPrivacy];
    if (allowPrivay) {
        privacyBlock(YES);
    } else {
        // PM 确认文案不需要国际化处理
        NSString *propId = self.cameraService.effect.currentSticker.effectIdentifier;
        [ACCAlert() showAlertWithTitle:@"提示"
                           description:@"为了更好的展现道具效果，您拍摄的素材需要上传至服务器识别地标建筑，识别完成后将立即删除。"
                                 image:nil
                     actionButtonTitle:@"同意"
                     cancelButtonTitle:@"再想想"
                           actionBlock:^{
            [self.viewModel trackPrivacy:YES propId:propId];
            privacyBlock(YES);
            [ACCCache() setBool:YES forKey:kCacheKeyPrivacy];
        }
                           cancelBlock:^{
            [self.viewModel trackPrivacy:NO propId:propId];
            privacyBlock(NO);
        }];
    }
}

- (void)sendMessageToEffect:(NSDictionary *)body taskId:(NSInteger)taskId
{
    IESMMEffectMessage *message = [[IESMMEffectMessage alloc] init];
    message.type = IESMMEffectMsgOther;
    message.msgId = kUserinfoMsgId;
    message.arg1 = kUserinfoMsgId;
    message.arg2 = taskId;
    message.arg3 = nil;
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSAssert(!error, @"json serialization failed, body=%@|error=%@", body, error);
    AWELogToolInfo(AWELogToolTagNone, @"send msg to effect, jsonString=%@", jsonString);
    if (!error) {
        message.arg3 = jsonString;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.cameraService.message sendMessageToEffect:message];
        });
    } else {
        AWELogToolError(AWELogToolTagNone, @"poi component send msg failed, error=%@", error);
    }
}

@end
