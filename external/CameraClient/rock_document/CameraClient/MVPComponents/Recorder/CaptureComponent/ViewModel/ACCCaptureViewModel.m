//
//  ACCCaptureViewModel.m
//  CameraClient
//
//  Created by 郝一鹏 on 2020/5/7.
//

#import "ACCCaptureViewModel.h"

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>
#import "ACCEffectMessageDownloader.h"
#import "ACCEffectDownloadParam.h"

#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <EffectPlatformSDK/EffectPlatform.h>

static NSString * const kInterfaceKey = @"interface";
static NSString * const kInterfaceValueToast = @"clientToast";
static NSString * const kInterfaceValueDownloadModel = @"downloadModel";
static NSString * const kInterfaceValueRequest = @"requestServerMessage";
static NSString * const kInterfaceValueResponse = @"onMessage";
static NSString * const kInterfaceValueDownload = @"download";
static NSString * const kStatusKey = @"status";

static NSString * const kEffectToastTypePrompt = @"prompt";
static NSString * const kEffectToastTypeLoading = @"loading";
static NSString * const kRequestTypeKey = @"request_type";
static NSString * const kRequestURLKey = @"request_url";

static const NSInteger kPropNetworkMessageId = 0x29;

typedef NS_ENUM(NSInteger, AWEPropRequestError) {
    AWEPropRequestErrorSuccess = 0,
    AWEPropRequestErrorReachability = 1,
    AWEPropRequestErrorServer = 2, // example: HTTP error 5xx
    AWEPropRequestErrorOther = 3
};


@interface ACCCaptureViewModel ()

@property (nonatomic, strong) id<ACCNetworkReachabilityProtocol> reachabilityManager;

@property (nonatomic, strong) ACCEffectMessageDownloader *downloader;

@property (nonatomic, strong, readwrite) RACSubject *captureReadyForSwitchModeSubject;

@end


@implementation ACCCaptureViewModel
IESAutoInject(ACCBaseServiceProvider(), reachabilityManager, ACCNetworkReachabilityProtocol)

- (instancetype)init {
    if (self = [super init]) {
        _downloader = [ACCEffectMessageDownloader sharedDownloader];
    }
    return self;
}

- (void)dealloc
{
    [_captureReadyForSwitchModeSubject sendCompleted];
}

- (void)handleEFfectMessageWithArg2:(NSInteger)arg2 arg3:(NSString *)arg3
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

- (void)send_captureReadyForSwitchModeSignal:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.captureReadyForSwitchModeSubject sendNext:RACTuplePack(mode, oldMode)];
}

#pragma mark - Private

- (void)handleJson:(NSDictionary *)json taskId:(NSInteger)taskId
{
    NSString *interface = [json acc_stringValueForKey:kInterfaceKey];
    if ([interface isEqualToString:kInterfaceValueToast]) {
        NSDictionary *body = [json acc_dictionaryValueForKey:@"body"];
        [self handleToastWithReceiveBody:body taskId:taskId];
    } else if ([interface isEqualToString:kInterfaceValueRequest]) {
        [self handleRequestWithJson:json taskId:taskId];
    } else if ([interface isEqualToString:kInterfaceValueDownload]) {
        NSArray *array = [json acc_arrayValueForKey:@"data"];
        [self handleDownloadWithJsonArray:array taskId:taskId];
    } else if ([interface isEqualToString:kInterfaceValueDownloadModel]) {
        [self handleDownloadModelWithJson:json taskId:taskId];
    }
}

#pragma mark - Toast

- (void)handleToastWithReceiveBody:(NSDictionary *)receiveBody taskId:(NSInteger)taskId
{
    NSMutableDictionary *sendBody = [NSMutableDictionary dictionary];
    sendBody[kInterfaceKey] = kInterfaceValueToast;
    
    if (![receiveBody isKindOfClass:NSDictionary.class]) {
        NSAssert(NO, @"receiveBody is not kind of NSDictionary");
        // hide toast if can not parse
        if (self.loadingHandler) {
            self.loadingHandler(YES, nil);
        }
        return;
    }
    
    NSString *type = [receiveBody acc_stringValueForKey:@"type"];
    NSString *text = [receiveBody acc_stringValueForKey:@"text"];
    if ([type isEqualToString:kEffectToastTypePrompt]) {
        if (self.toastHandler) {
            self.toastHandler(text);
        }
    } else if ([type isEqualToString:kEffectToastTypeLoading]) {
        BOOL close = [receiveBody[@"close"] boolValue];
        if (self.loadingHandler) {
            self.loadingHandler(close, text);
        }
    }
}

#pragma mark - Requst

- (void)handleRequestWithJson:(NSDictionary *)dict taskId:(NSInteger)taskId
{
    AWELogToolDebug(AWELogToolTagNone, @"handle request, dict=%@|taskId=%zi", dict, taskId);
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    messageDict[kInterfaceKey] = kInterfaceValueResponse;
    messageDict[kStatusKey] = @(0);
    messageDict[@"body"] = @{};
    
    NSString *urlString = @"";
    NSString *method = @"";
    
    if ([dict[kRequestURLKey] isKindOfClass:NSString.class]) {
        urlString = [dict acc_stringValueForKey:kRequestURLKey];
    }
    if (urlString.length == 0) {
        AWELogToolWarn(AWELogToolTagNone, @"effect network url is empty");
    }
    messageDict[kRequestURLKey] = urlString;
    
    if ([dict[kRequestTypeKey] isKindOfClass:NSString.class]) {
        method = [dict acc_stringValueForKey:kRequestTypeKey];
    }
    if (method.length == 0) {
        AWELogToolWarn(AWELogToolTagNone, @"effect network method is empty");
    }
    method = [method uppercaseString];
    if (![method isEqualToString:@"GET"] && ![method isEqualToString:@"POST"]) {
        NSAssert(NO, @"request method(%@) is invaild", method);
        messageDict[kStatusKey] = @(AWEPropRequestErrorOther);
        [self sendMessageToEffect:messageDict taskId:taskId msgId:kPropNetworkMessageId];
        return;
    }
    
    NSDictionary *params = [dict acc_dictionaryValueForKey:@"body"];
    
    @weakify(self);
    [self requestWithMethod:method urlString:urlString params:params completion:^(id data, NSError *error) {
        @strongify(self);
        if (error) {
            NSErrorDomain apiErrorDomain = [ACCNetService() apiErrorDomain];
            NSErrorDomain networkErrorDomain = [ACCNetService() networkErrorDomain];
            AWELogToolError(AWELogToolTagNone, @"request with method failed, urlString=%@|error=%@", urlString, error);
            
            if ([error.domain isEqualToString:networkErrorDomain]) {
                messageDict[kStatusKey] = @(AWEPropRequestErrorReachability);
            } else if ([error.domain isEqualToString:apiErrorDomain]) {
                // 业务错误码，透传服务端内容
                messageDict[@"body"] = data;
                messageDict[kStatusKey] = @(AWEPropRequestErrorSuccess);
            } else {
                messageDict[kStatusKey] = self.reachabilityManager.isReachable ? @(AWEPropRequestErrorServer) : @(AWEPropRequestErrorReachability);
            }
            
            [self sendMessageToEffect:messageDict taskId:taskId msgId:kPropNetworkMessageId];
        } else {
            messageDict[@"body"] = data;
            [self sendMessageToEffect:messageDict taskId:taskId msgId:kPropNetworkMessageId];
        }
    }];
}

- (void)requestWithMethod:(NSString *)method
                urlString:(NSString *)urlString
                   params:(NSDictionary *)params
               completion:(void(^)(id data, NSError *error))completion
{
    if ([method isEqualToString:@"GET"]) {
        [ACCNetService() GET:urlString
                      params:params
                  modelClass:nil
                  completion:^(id  _Nullable model, NSError * _Nullable error) {
            if (completion) {
                completion(model, error);
            }
        }];
    } else if ([method isEqualToString:@"POST"]) {
        [ACCNetService() POST:urlString
                       params:params
                   modelClass:nil
                   completion:^(id  _Nullable model, NSError * _Nullable error) {
            if (completion) {
                completion(model, error);
            }
        }];
    }
}

#pragma mark - Download

- (void)handleDownloadWithJsonArray:(NSArray *)array taskId:(NSInteger)taskId
{
    // key 为 urlString 对应的 index
    NSMutableDictionary<NSNumber *, NSDictionary *> *filePathsDict = [NSMutableDictionary dictionary];
    void (^downloadCallback)(NSInteger, NSString *, NSError *) = ^(NSInteger idx, NSString * _Nullable filePathString, NSError *error) {
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"download failed, filePathString=%@|error=%@", filePathString, error);
        }
        NSInteger success = (error == nil) ? 1 : 0;
        NSDictionary *dict = @{
            @"path" : filePathString ?: @"",
            @"success" : @(success),
        };
        
        filePathsDict[@(idx)] = dict;
    };
    
    NSError *parseError = nil;
    NSArray<ACCEffectDownloadParam *> *urlParams = [MTLJSONAdapter modelsOfClass:ACCEffectDownloadParam.class fromJSONArray:array error:&parseError];
    NSAssert(!parseError, @"json parse error!!!, error=%@", parseError);
    if (parseError) {
        AWELogToolError(AWELogToolTagNone, @"send body due to urlParams is empty, parseError=%@", parseError);
        [self sendMessageToEffect:@{kInterfaceKey : kInterfaceValueDownload} taskId:taskId msgId:kPropNetworkMessageId];
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
        
    // file_paths 和 url_list 顺序严格一一对应
    [urlParams enumerateObjectsUsingBlock:^(ACCEffectDownloadParam * _Nonnull param, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_group_enter(group);
        
        [self.downloader downloadWithUrlList:param.urlList
                                   needUpzip:param.needUpzip
                                  completion:^(NSURL * _Nullable filePath, NSError * _Nullable error) {
            downloadCallback(idx, filePath.path, error);
            
            dispatch_group_leave(group);
        }];;
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[kInterfaceKey] = kInterfaceValueDownload;
        NSMutableArray<NSDictionary *> *filePaths = [NSMutableArray array];
        response[@"file_paths"] = filePaths;
        
        for (NSInteger i = 0; i < urlParams.count; i++) {
            NSDictionary *dict = filePathsDict[@(i)];
            NSAssert(dict, @"dict is invaild!!!, i = %zi", i);
            [filePaths addObject:dict];
        }
        
        [self sendMessageToEffect:response taskId:taskId msgId:kPropNetworkMessageId];
    });
}

#pragma mark - downloadModel

- (void)handleDownloadModelWithJson:(NSDictionary *)dict taskId:(NSInteger)taskId
{
    NSString *modelName = [dict acc_stringValueForKey:@"model"] ?: @"";
    @weakify(self);
    [EffectPlatform fetchOnlineInfosAndResourcesWithModelNames:@[modelName] extra:@{@"busi_id" : @7} completion:^(BOOL success, NSError * _Nonnull error) {
        if (error || !success) {
            AWELogToolError(AWELogToolTagNone, @"fetch resource with model failed, modelName=%@|error=%@", modelName, error);
        }
        
        @strongify(self);
        NSMutableDictionary *sendBody = [NSMutableDictionary dictionary];
        sendBody[kInterfaceKey] = kInterfaceValueDownloadModel;
        sendBody[kStatusKey] = (!error && success) ? @0 : @1;
        sendBody[@"model"] = modelName ?: @"";

        [self sendMessageToEffect:sendBody taskId:taskId msgId:kPropNetworkMessageId];
    }];
}

- (void)sendMessageToEffect:(NSDictionary *)body taskId:(NSInteger)taskId msgId:(NSInteger)msgId
{
    IESMMEffectMessage *message = [[IESMMEffectMessage alloc] init];
    message.type = IESMMEffectMsgOther;
    message.msgId = msgId;
    message.arg1 = msgId; // arg1 和 msgId 相同
    message.arg2 = taskId;
    message.arg3 = nil;
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSAssert(!error, @"json serialization failed, body=%@|error=%@", body, error);
    
    if (!error) {
        message.arg3 = jsonString;
        AWELogToolInfo(AWELogToolTagNone, @"send msg to effect, msgId=%zi|arg1=%zi|arg2=%zi|arg3=%@",
                       message.msgId, message.arg1, message.arg2, message.arg3);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (self.sendMessageHandler) {
                self.sendMessageHandler(message);
            }
        });
    } else {
        AWELogToolError(AWELogToolTagNone, @"poi component send msg failed, error=%@", error);
    }
}

#pragma mark - ACCCaptureService

- (RACSignal <ACCRecordModeChangePack> *)captureReadyForSwitchModeSignal
{
    return self.captureReadyForSwitchModeSubject;
}

- (RACSubject *)captureReadyForSwitchModeSubject
{
    if (!_captureReadyForSwitchModeSubject) {
        _captureReadyForSwitchModeSubject = [RACSubject subject];
    }
    return _captureReadyForSwitchModeSubject;
}

@end
