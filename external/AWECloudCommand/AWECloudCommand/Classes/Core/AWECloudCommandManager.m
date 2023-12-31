
//
//  AWECloudCommandManager.m
//  Aweme
//
//  Created by willorfang on 2017/1/15.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWECloudCommandManager.h"
#import "AWECloudControlDecode.h"
#import "AWECloudCommandNetworkUtility.h"
#import "NSDictionary+AWECloudCommandUtil.h"
#import "NSString+AWECloudCommandUtil.h"
#import "AWECloudBackgroundTaskUtility.h"
#import <BDNetworkTag/BDNetworkTagManager.h>
#include <pthread.h>
#import "NSString+AWECloudCommandUtil.h"

static NSString *const kDefaultHost = @"bW9uLnppamllYXBpLmNvbQ=="; //mon.zijieapi.com
#define kAWECloudCommandPostURLString ([NSString stringWithFormat:@"https://%@/monitor/collect/c/cloudcontrol/file/", self.host])
#define kAWEGetCloudCommandURLString ([NSString stringWithFormat:@"https://%@/monitor/collect/c/cloudcontrol/get", self.host])

static const NSUInteger kMaxCurrentOperationCount = 2;
static const NSTimeInterval kMinCommandInterval = 3 * 60.f;

//////////////////////////////////////////////////////////////////////////////////////////

@implementation AWECustomCommandResult

- (instancetype)init
{
    if (self) {
        self = [super init];
        _status = AWECloudCommandStatusSucceed;
        _fileType = @"unknown";
    }
    return self;
}

@end


@implementation AWECloudCommandParamModel

- (instancetype)init
{
    if (self) {
        _appBuildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    }
    return self;
}

@end


@interface AWECloudCommandManager () {
    pthread_rwlock_t _customClsRWLock;
}

@property (nonatomic, strong, nonnull) dispatch_queue_t workQueue;
@property (nonatomic, strong, nonnull) NSOperationQueue *commandExecutionQueue;
@property (nonatomic, strong) NSMutableArray<Class<AWECustomCommandHandler>> *customCommandHandlerClsMutableArray;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *commandIDDic;

@end


@implementation AWECloudCommandManager

+ (instancetype)sharedInstance
{
    static AWECloudCommandManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWECloudCommandManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _workQueue = dispatch_queue_create("com.bytedance.AWECloudCommandManager", DISPATCH_QUEUE_SERIAL);
        _commandExecutionQueue = [[NSOperationQueue alloc] init];
        _commandExecutionQueue.maxConcurrentOperationCount = kMaxCurrentOperationCount;
        _commandExecutionQueue.name = @"com.bytedance.AWECloudCommandManager.executionQueue";
        pthread_rwlock_init(&_customClsRWLock, NULL);
        _customCommandHandlerClsMutableArray = [[NSMutableArray alloc] init];
        _commandIDDic = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCloudCommandDataByPush:) name:@"kPushSDKSilentPushNotification" object:nil];
    }
    return self;
}

- (void)addCustomCommandHandlerCls:(Class<AWECustomCommandHandler>)handlerCls
{
    pthread_rwlock_wrlock(&_customClsRWLock);
    BOOL hasRegistered = [self.customCommandHandlerClsMutableArray containsObject:handlerCls];
    if (!hasRegistered) {
        [self.customCommandHandlerClsMutableArray addObject:handlerCls];
    }
    pthread_rwlock_unlock(&_customClsRWLock);
}

- (void)addCustomCommandHandlerClsArray:(NSArray<Class<AWECustomCommandHandler>> *)handlerClsArray
{
    for (Class<AWECustomCommandHandler> handlerCls in handlerClsArray) {
        [self addCustomCommandHandlerCls:handlerCls];
    }
}

- (void)getCloudControlCommandData
{
    [self _getCloudControlCommandDataWithPushParams:nil];
}

- (void)getCloudCommandDataByPush:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:NSDictionary.class]) {
        NSString *pushStr = [(NSDictionary *)notification.object valueForKey:@"extra_str"];
        if (pushStr) {
            NSTimeInterval timeStamep = [[NSDate date] timeIntervalSince1970];
            NSString *taskName = [NSString stringWithFormat:@"cloud_command_task_%lld", (int64_t)timeStamep];
            [AWECloudBackgroundTaskUtility detachBackgroundTaskWithName:taskName expireTime:120 task:^(void (^ _Nonnull completeHandle)(void)) {
                [self _getCloudControlCommandDataWithPushParams:pushStr];
            }];
        }
    }
}

- (void)_getCloudControlCommandDataWithPushParams:(NSString *)pushStr
{
    @try {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        NSDictionary *commonParams = self.commonParams;
        if(commonParams) {
            [params addEntriesFromDictionary:commonParams];
        }
        
        [params setValue:self.cloudCommandParamModel.deviceId forKey:@"device_id"];
        [params setValue:self.cloudCommandParamModel.appID forKey:@"aid"];
        [params setValue:self.cloudCommandParamModel.userId forKey:@"user_id"];
        [params setValue:self.cloudCommandParamModel.appBuildVersion forKey:@"update_version_code"];
        [params setValue:kAWECloudCommandSDKVersion forKey:@"sdk_version"];
        if (pushStr) {
            [params setValue:pushStr forKey:@"cc_extra"];
        }
        
        // 为了兼容后端，post请求url里也需要拼接参数
        NSString *paramStr = [NSString awe_queryStringWithParamDictionary:params];
        paramStr = [paramStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *url = [kAWEGetCloudCommandURLString awe_urlStringByAddingComponentString:paramStr];
        
        NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [headerDict setValue:@"application/json" forKey:@"Content-Type"];
        [headerDict setValue:@"application/json" forKey:@"Accept"];
        [headerDict setValue:@"1" forKey:@"Version-Code"];
        [headerDict addEntriesFromDictionary:[BDNetworkTagManager autoTriggerTagInfo]];
        
        //slardar server only parse query string,so just put body empty to avoid network traffic waste
        [AWECloudCommandNetworkUtility requestWithUrl:url
                                        requestMethod:AWECloudCommandRequestMethodPost
                                               params:nil
                                       requestHeaders:[headerDict copy]
                                              success:^(id responseObject, NSData *data, NSString *ran) {
                                                  [self _executeCommandWithJsonObject:responseObject ran:ran];
                                              }
                                              failure:nil];
    } @catch (NSException *exception) {
    }
}

- (void)_executeCommandWithJsonObject:(NSDictionary *)jsonObject ran:(NSString *)ran
{
    dispatch_async(self.workQueue, ^{
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            return;
        }
        NSString *commandBase64Str = [jsonObject awe_cc_stringValueForKey:@"data"];
        if (commandBase64Str.length <= 0) {
            return;
        }
        
        [self executeCommandWithData:[commandBase64Str dataUsingEncoding:NSUTF8StringEncoding] ran:ran];
    });
}

- (void)executeCommandWithData:(NSData *)data
{
    NSAssert(NO, @"You cannot invoke this method, because this method has been deprecated when the version number of the AWECloudCommand is greater than or equal to [1.1.0]! \n"
                "You can pod AWECloudCommand with a version number below [1.1.0] or update the related module Heimdallr to the latest version.");
}

- (void)executeCommandWithData:(NSData *)data ran:(NSString *)ran
{
    dispatch_async(self.workQueue, ^{
        if (!data || ![data isKindOfClass:[NSData class]]) {
            return;
        }
        
        if (!ran || ![ran isKindOfClass:[NSString class]]) {
            return;
        }
        NSDictionary *jsonObject = [AWECloudControlDecode payloadWithDecryptData:data withKey:ran];
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            return;
        }
        NSArray *commandArray = [[jsonObject awe_cc_dictionaryValueForKey:@"configs"] awe_cc_arrayValueForKey:@"cloud_commands"];
        
        NSTimeInterval currentStamp = [[NSDate date] timeIntervalSince1970];
        for (NSDictionary *command in commandArray) {
            // Avoid to repeat execution in 3 minutes
            long long commandID = [command awe_cc_longlongValueForKey:@"command_id"];
            NSNumber *timeStamp = [self.commandIDDic objectForKey:@(commandID)];
            if (timeStamp && timeStamp.doubleValue + kMinCommandInterval > currentStamp) {
                return;
            }
            else {
                [self.commandIDDic setObject:@(currentStamp) forKey:@(commandID)];
            }
            
            __weak typeof(self) weakSelf = self;
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                __strong typeof(weakSelf) self = weakSelf;
                AWECloudCommandModel *model = [[AWECloudCommandModel alloc] initWithDict:command];
                [self _executeCommand:model];
            }];
            [self.commandExecutionQueue addOperation:operation];
        }
    });
}

#pragma mark - Private Methods

- (void)_executeCommand:(AWECloudCommandModel *)model
{
    if (!model) {
        return;
    }
    
    Class<AWECloudCommandProtocol> commandClass = AWECloudCommandForType(model.type);
    
    if (!commandClass) {
        AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
        result.commandId = model.commandId;
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [NSString stringWithFormat:@"The cloud type %@ is not supported in current project", model.type];
        result.fileType = @"text";
        result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
        [self _postCommandResponse:result];
        return;
    }
    
    ForbidCloudCommandUpload block = self.forbidCloudCommandUpload;
    if (block && block(model)) {
        AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
        
        result.commandId = model.commandId;
        result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
        result.status = AWECloudCommandStatusFail;
        NSString *errStr = [NSString stringWithFormat:@"Forbidding uploading the type %@ by host.", model.type];
        result.errorMessage = errStr;
        [self _postCommandResponse:result];
        return;
    }
    
    [model configFileBlockList:self.blockList];
    [[commandClass createInstance] excuteCommand:model completion:^(AWECloudCommandResult *result) {
        [self _postCommandResponse:result];
    }];
}

- (void)_saveCommandRetryNumbersWithKey:(NSString *)key
{
    NSInteger currentRetryNumbers = [self _getCommandRetryNumbersWithKey:key];
    currentRetryNumbers++;
    [[NSUserDefaults standardUserDefaults] setInteger:currentRetryNumbers forKey:key];
}

- (NSInteger)_getCommandRetryNumbersWithKey:(NSString *)key
{
    NSInteger retryNumbers = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    return retryNumbers;
}

- (void)_postCommandResponse:(AWECloudCommandResult *)result
{
    NSDictionary *paramDict = [self _paramDictionaryWithResult:result];
    successBlock successBlock = [^(id responseObject, NSData *data, NSString *ran) {
        int httpStatusCode = [responseObject awe_cc_intValueForKey:@"errno"];
        // Http状态码，200为请求成功
        if (httpStatusCode == 200) {
            AWESAFEBLOCK_INVOKE(result.uploadSuccessedBlock);
        } else {
            NSDictionary *userInfo = (NSDictionary *) [responseObject copy];
            NSError *error = [NSError errorWithDomain:@"com.snssdk.mon.collect" code:httpStatusCode userInfo:userInfo];
            AWESAFEBLOCK_INVOKE(result.uploadFailedBlock, error);
        }
    } copy];
    failureBlock failureBlock = [^(NSError *error) {
        AWESAFEBLOCK_INVOKE(result.uploadFailedBlock, error);
    } copy];
    
    NSString *URLString = kAWECloudCommandPostURLString;
    NSDictionary *tmpCommonParams = self.commonParams;
    NSMutableDictionary *commonParams = (tmpCommonParams?:@{}).mutableCopy;
    if (result.additionalUploadParams) {
        [commonParams addEntriesFromDictionary:result.additionalUploadParams];
    }
    
    if (commonParams.count > 0) {
        NSString *paramStr = [NSString awe_queryStringWithParamDictionary:self.commonParams];
        paramStr = [paramStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        URLString = [URLString awe_urlStringByAddingComponentString:paramStr];
    }
    
    if (result.isMultiData) {
        [AWECloudCommandNetworkUtility uploadMultiDataWithUrl:URLString
                                                    dataArray:result.multiDataArray
                                                       params:paramDict
                                                 commonParams:commonParams
                                               requestHeaders:nil
                                                      success:successBlock
                                                      failure:failureBlock];
    }
    else {
        [AWECloudCommandNetworkUtility uploadDataWithUrl:URLString
                                                fileName:result.fileName ?: @""
                                                fileType:result.fileType ?: @""
                                                    data:result.data ?: [NSData data]
                                                  params:paramDict
                                            commonParams:commonParams
                                                mimeType:result.mimeType ? : @""
                                          requestHeaders:nil
                                                 success:successBlock
                                                 failure:failureBlock];
    }
}

- (NSDictionary *)_paramDictionaryWithResult:(AWECloudCommandResult *)result
{
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
    [paramDict setValue:result.commandId forKey:@"cid"];
    [paramDict setValue:@(result.status) forKey:@"status"];
    [paramDict setValue:result.errorMessage forKey:@"err_msg"];
    [paramDict setValue:@(result.operateTimestamp) forKey:@"operate_time"];
    [paramDict setValue:self.cloudCommandParamModel.userId forKey:@"uid"];
    [paramDict setValue:self.cloudCommandParamModel.appBuildVersion forKey:@"update_version_code"];
    [paramDict setValue:kAWECloudCommandSDKVersion forKey:@"sdk_version"];
    [paramDict setValue:self.cloudCommandParamModel.appID forKey:@"aid"];
    [paramDict setValue:@"iOS" forKey:@"os"];
    
    if (self.commonParams.count) {
        [paramDict addEntriesFromDictionary:self.commonParams];
    }
    return paramDict;
}

#pragma mark - Properties

- (NSDictionary *)commonParams
{
    return AWESAFEBLOCK_INVOKE(_commonParamsBlock);
}

- (AWECloudCommandParamModel *)cloudCommandParamModel
{
    return AWESAFEBLOCK_INVOKE(_cloudCommandParamModelBlock);
}

- (NSArray *)customCommandHandlerClsArray
{
    pthread_rwlock_rdlock(&_customClsRWLock);
    NSArray *results = [self.customCommandHandlerClsMutableArray copy];
    pthread_rwlock_unlock(&_customClsRWLock);
    
    return results;
}

- (void)setNetworkDelegate:(id<AWECloudCommandNetworkDelegate>)networkDelegate
{
    [AWECloudCommandNetworkHandler sharedInstance].networkDelegate = networkDelegate;
}

- (NSString *)host
{
    return _host.length ? _host : [kDefaultHost cloudcommand_base64Decode];
}

@end

