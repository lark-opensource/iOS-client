//
//  BDPJSBridgeUtil.m
//  Timor
//
//  Created by 王浩宇 on 2019/8/29.
//

#import "BDPJSBridgeUtil.h"
#import <OPFoundation/BDPTracker.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/BDPMacroUtils.h>
#import <ECOInfra/BDPLog.h>
#import <OPPluginManagerAdapter/OPPluginManagerAdapter-Swift.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

// error code js callback key
NSString *const kBDPJSCallbackErrCodeKey = @"errCode";
// error message js callback key
NSString *const kBDPJSCallbackErrMsgKey = @"errMsg";

void BDPMonitorFailedEvent(NSString *event, BDPJSBridgeCallBackType type, NSString *errMsg, BDPUniqueID *uniqueID)
{
    if (BDPJSBridgeCallBackTypeSuccess != type) {
        [BDPTracker monitorService:@"mp_api_error"
                            metric:@{}
                          category:@{@"event": event ?: @"",
                                     @"type": @(type)}
                             extra:@{@"errMsg": errMsg ?: @""}
              uniqueID:uniqueID];
    }
}

NSString *BDPResultMsgFromStatus(BDPJSBridgeCallBackType status)
{
    NSString *result = @"fail ";

    switch (status) {
        case BDPJSBridgeCallBackTypeSuccess:
            result = @"ok";
            break;
        case BDPJSBridgeCallBackTypeUserCancel:
            result = @"cancel ";
            break;
        default:
            result = @"fail ";
            break;
    }
    return result;
}

// 错误信息原拼接逻辑：
// errMsg = "ok"/"fail "/"cancel " + codeMessage + " " + data["errMsg"]
NSString *BDPErrorMessageForStatus(BDPJSBridgeCallBackType status)
{
    NSString *result = @"";

    switch (status) {
        case BDPJSBridgeCallBackTypeNoUserPermission:
            result = @"auth deny";
            break;
        case BDPJSBridgeCallBackTypeNoSystemPermission:
            result = @"system auth deny";
            break;
        case BDPJSBridgeCallBackTypeNoPlatformPermission:
            result = @"platform auth deny";
            break;
        case BDPJSBridgeCallBackTypeInvalidScope:
            result = @"invalid scope";
            break;
        case BDPJSBridgeCallBackTypeNoHandler:
        case BDPJSBridgeCallBackTypeNoHostHandler:
            result = @"feature is not supported in app";
            break;
        case BDPJSBridgeCallBackTypeParamError:
            result = @"param:";
            break;
        case BDPJSBridgeCallBackTypeNoAuthorization:
            result = @"bdp authorization missed";
            break;
        default:
            break;
    }
    return result;
}

BDPJSBridgeCallBackType BDPApiCode2CallBackType(NSInteger apiCode) {
    if (apiCode == OPGeneralAPICodeOk)
        return BDPJSBridgeCallBackTypeSuccess;
    else if (apiCode == OPGeneralAPICodeUnkonwError)
        return BDPJSBridgeCallBackTypeFailed;
    else if (apiCode == OPGeneralAPICodeCancel)
        return BDPJSBridgeCallBackTypeUserCancel;
    else if (apiCode == OPGeneralAPICodeUserAuthDenied)
        return BDPJSBridgeCallBackTypeNoUserPermission;
    else if (apiCode == OPGeneralAPICodeSystemAuthDeny)
        return BDPJSBridgeCallBackTypeNoSystemPermission;
//    else if (apiCode == OPGeneralAPICodePlatformAuthDeny)
//        return BDPJSBridgeCallBackTypeNoPlatformPermission;// 平台授权失败错误统一移除
    else if (apiCode == AuthorizeAPICodeInvalidScope)//https://bytedance.feishu.cn/sheets/shtcnVPga52UEc1yAfIOhPhW7Ad?sheet=u7CesS 见讨论
        return BDPJSBridgeCallBackTypeInvalidScope;   // 已移动到业务JSAPI【authorize】 code 范围内
    else if (apiCode == OPGeneralAPICodeUnable)
        return BDPJSBridgeCallBackTypeNoHandler;
    else if (apiCode == OPGeneralAPICodeUnable)
        return BDPJSBridgeCallBackTypeNoHostHandler;
    else if (apiCode == OPGeneralAPICodeParam)
        return BDPJSBridgeCallBackTypeParamError;
//    else if (apiCode == OPGeneralAPICodeset)
//        return BDPJSBridgeCallBackTypeNoAuthorization; // 不对外暴露该错误，返回错误即可 @yinyuan
    else
        return BDPJSBridgeCallBackTypeFailed;
}

/// 2019.12.6 增加uniqueID参数用于errorMsg上报通用参数
NSDictionary *BDPProcessJSCallback(NSDictionary *response, NSString *event, BDPJSBridgeCallBackType status, BDPUniqueID *uniqueID)
{
    NSMutableDictionary *mutableDict = response? [response mutableCopy]: [[NSMutableDictionary alloc] init];
    NSString *appendErrorMsg = [mutableDict bdp_stringValueForKey:@"errMsg"];
    NSString *result = BDPResultMsgFromStatus(status);
    NSString *errMsg = @"";

    if (appendErrorMsg) {
        errMsg = [NSString stringWithFormat:@"%@:%@%@", event, result, appendErrorMsg];
        
    } else {
        errMsg = [NSString stringWithFormat:@"%@:%@", event, result];
    }

    // 为对齐微信errMsg, 又保持原有接口errMsg拼接方式，添加此替换规则
    errMsg = [errMsg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [mutableDict setValue:errMsg forKey:@"errMsg"];
    
    BDPMonitorFailedEvent(event, status, errMsg, uniqueID);
    
    return [mutableDict copy];
}

void OPAPIReportResult(BDPJSBridgeCallBackType status, NSDictionary *response, OPMonitorEvent *event) {
    switch (status) {
    case BDPJSBridgeCallBackTypeSuccess:
            event.setResultTypeSuccess();
            break;
    case BDPJSBridgeCallBackTypeUserCancel:
            event.setResultTypeCancel();
            break;
    default:
            event.setResultTypeFail();
    }
    if (status != BDPJSBridgeCallBackTypeSuccess) {
        NSString *errMsg = [response bdp_stringValueForKey:@"errMsg"];
        if ([response bdp_objectForKey:@"errCode"]) {
            event.kv(@"errCode", [response bdp_integerValueForKey:@"errCode"]);
        }
        if (errMsg) {
            event.kv(@"errMsg", errMsg);
        }
        if (event.innerMonitorCode.code == APIMonitorCodeCommon.native_callback_invoke.code) {
            // errno is exclusive keyword, so snake err_no in ObjC
            NSString *err_no = response[@"errno"];
            NSString *err_string = response[@"errString"];
            if (err_no && err_string) {
                event.kv(@"errno", err_no);
                event.kv(@"errString", err_string);
            }
        }
    }
}

BDPJSBridgeCallBackType BDPMatchCallBackByPermissionResult(BDPAuthorizationPermissionResult result)
{
    switch (result) {
        case BDPAuthorizationPermissionResultEnabled:
            return BDPJSBridgeCallBackTypeSuccess;
            break;
        case BDPAuthorizationPermissionResultUserDisabled:
            return BDPJSBridgeCallBackTypeNoUserPermission;
            break;
        case BDPAuthorizationPermissionResultSystemDisabled:
            return BDPJSBridgeCallBackTypeNoSystemPermission;
            break;
        case BDPAuthorizationPermissionResultInvalidScope:
            return BDPJSBridgeCallBackTypeInvalidScope;
            break;
        case BDPAuthorizationPermissionResultPlatformDisabled:
            return BDPJSBridgeCallBackTypeNoPlatformPermission;
            break;
        default:
            return BDPJSBridgeCallBackTypeUnknown;
            break;
    }
}

NSString *BDPMatchRequestResultByPermissionResult(BDPAuthorizationPermissionResult result)
{
    switch (result) {
        case BDPAuthorizationPermissionResultEnabled:
            return @"ok";
            break;
        case BDPAuthorizationPermissionResultUserDisabled:
            return @"auth deny";
            break;
        case BDPAuthorizationPermissionResultSystemDisabled:
            return @"system auth deny";
            break;
        case BDPAuthorizationPermissionResultInvalidScope:
            return @"invalid scope";
            break;
        case BDPAuthorizationPermissionResultPlatformDisabled:
            return @"platform auth deny";
            break;
        default:
            return @"deny";
            break;
    }
}

@interface OPAPICallback ()

/// 回调函数
@property (nonatomic, copy) BDPJSBridgeCallback callback;

/// BDPJSBridgeEngine 引擎实例，weak
@property (nonatomic, weak) BDPJSBridgeEngine engine;

/// BDPPluginContext 实例，weak
@property (nonatomic, weak) BDPPluginContext context;

/// 回调数据
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *callbackData;

/// 扩展日志信息
@property (nonatomic, strong) NSMutableString *exLogInfo;

/// 是否已回调
@property (nonatomic, assign) BOOL invoked;

/// api 名
@property (nonatomic, strong) NSString *apiName;

/// 文件名
@property (nonatomic, copy) NSString *fileName;

/// 方法名
@property (nonatomic, copy) NSString *funcName;

/// 代码行
@property (nonatomic, assign) NSInteger line;

@end

@implementation OPAPICallback

- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                   engine:(BDPJSBridgeEngine _Nullable)engine
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line
{
    return [self initWithCallback:callback engine:engine context:nil fileName:fileName funcName:funcName line:line];
}

- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                  context:(BDPPluginContext _Nullable)context
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line
{
    return [self initWithCallback:callback engine:nil context:context fileName:fileName funcName:funcName line:line];
}

- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                   engine:(BDPJSBridgeEngine _Nullable)engine
                                  context:(BDPPluginContext _Nullable)context
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line
{
    self = [super init];
    if (self) {
        self.callback = callback;
        self.engine = engine;
        self.context = context;

        self.callbackData = NSMutableDictionary.dictionary;
        self.exLogInfo = NSMutableString.string;

        self.fileName = fileName ? [NSString stringWithUTF8String:fileName] : nil;
        self.funcName = funcName ? [NSString stringWithUTF8String:funcName] : nil;
        self.line = line;

        // 从 funcName 解析 apiName
        [self parseApiName];

    }
    return self;
}

- (void)dealloc {
    if (!self.invoked) {
        BDPAssertWithLog(@"you may forget to invoke the callback for the api, please check the logic right now. api:%@ file:%@ function:%@ line:%@", self.apiName, self.fileName, self.funcName, @(self.line));
    }
}

/// 从 funcName 解析 apiName，这里对函数名格式是有要求的，增加了校验逻辑
- (void)parseApiName {
    if (self.funcName) {
        // 形如 [TMAPluginTracker systemLogWithParam:callback:engine:controller:] 或者 [TMAPluginTracker monitorReportWithParam:callback:context:]
        NSRange beginRange = [self.funcName rangeOfString:@" "];
        NSRange endRange = [self.funcName rangeOfString:@"WithParam:"];
        if (beginRange.location > 0 && beginRange.length > 0 && endRange.location > 0 && endRange.length > 0) {
            NSInteger beginIndex = beginRange.location+beginRange.length;
            self.apiName = [self.funcName substringWithRange:NSMakeRange(beginIndex, endRange.location - beginIndex)];
        } else {
            BDPAssertWithLog(@"the api funcName has changed pattern, please fix this logic.");
        }
    } else {
        BDPAssertWithLog(@"the api funcName should not be nil.");
    }
}

/*----------------------------------------------------------*/
//                         组装数据
/*----------------------------------------------------------*/
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable errMsg))errMsg {
    WeakSelf;
    return ^OPAPICallback *(NSString * _Nullable errMsg) {
        StrongSelf;
        if (!self) {
            return nil;
        }
        if (!self.invoked) {
            self.addKeyValue(kBDPJSCallbackErrMsgKey, errMsg);
        }
        return self;
    };
}

- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nonnull key, id _Nullable value))addKeyValue {
    WeakSelf;
    return ^OPAPICallback *(NSString * _Nonnull key, id _Nullable value) {
        StrongSelf;
        if (!self) {
            return nil;
        }
        if (!self.invoked && key) {
            @synchronized (self) {
                self.callbackData[key] = value;
            }
        }
        return self;
    };
}

- (OPAPICallback * _Nonnull (^ _Nonnull)(NSDictionary * _Nullable map))addMap {
    WeakSelf;
    return ^OPAPICallback *(NSDictionary * _Nullable map) {
        StrongSelf;
        if (!self) {
            return nil;
        }
        if (!self.invoked && !BDPIsEmptyDictionary(map)) {
            @synchronized (self) {
                [self.callbackData addEntriesFromDictionary:map];
            }
        }
        return self;
    };
}


/*----------------------------------------------------------*/
//                    执行 callback 回调
/*----------------------------------------------------------*/
- (void (^ _Nonnull)(BDPJSBridgeCallBackType status, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line))__invokeStatusWithContextInfo {
    WeakSelf;
    return ^void(BDPJSBridgeCallBackType status, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line) {
        StrongSelfIfNilReturn;
        if (!self.invoked) {
            NSDictionary *callbackData = nil;
            @synchronized (self) {
                callbackData = self.callbackData.copy;
            }
            if (self.callback) {
                self.callback(status, callbackData);
            } else {
                [self logLevel:BDPLogLevelError
                      fileName:fileName
                      funcName:funcName
                          line:line
                       message:@"callback is nil"];
            }

            // 默认输出日志
            if (status == BDPJSBridgeCallBackTypeSuccess) {
                // success 默认不打日志
                [self logLevel:BDPLogLevelDebug
                      fileName:fileName
                      funcName:funcName
                          line:line
                       message:[NSString stringWithFormat:@"api callback %@:%@%@", self.apiName, BDPResultMsgFromStatus(status), BDPErrorMessageForStatus(status)]];
            } else {
                [self logLevel:(status == BDPJSBridgeCallBackTypeUserCancel ? BDPLogLevelWarn : BDPLogLevelError)
                      fileName:fileName
                      funcName:funcName
                          line:line
                       message:[NSString stringWithFormat:@"api callback %@:%@%@ %@", self.apiName, BDPResultMsgFromStatus(status), BDPErrorMessageForStatus(status), self.callbackData]];
            }

            self.callbackData = nil;
            self.invoked = YES;
        } else {
            BDPAssertWithLog(@"you may invoke the callback multiple times, please check the logic right now. api:%@ file:%@ function:%@ line:%@", self.apiName, self.fileName, self.funcName, @(self.line));
        }
    };
}

/*----------------------------------------------------------*/
//                         日志
/*----------------------------------------------------------*/

- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable name, id _Nullable value))addLogValue {
    WeakSelf;
    return ^OPAPICallback *(NSString * _Nullable name, id _Nullable value) {
        StrongSelf;
        if (!self) {
            return nil;
        }
        if (!BDPIsEmptyString(name)) {
            self.addLogMessage(@"%@:%@", name, value);
        }
        return self;
    };
}

- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable message, ...))addLogMessage {
    WeakSelf;
    return ^OPAPICallback *(NSString * _Nullable message, ...) {
        StrongSelf;
        if (!self) {
            return nil;
        }
        if (!BDPIsEmptyString(message)) {
            @synchronized (self) {
                if (self.exLogInfo.length > 0) {
                    // 后面新增的日志信息，前面加一个 逗号+空格
                    [self.exLogInfo appendString:@", "];
                }
                [self.exLogInfo appendString:message];
            }
        }
        return self;
    };
}

- (OPAPICallback * _Nonnull (^ _Nonnull)(BDPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message))__logWithContextInfo {
    WeakSelf;
    return ^OPAPICallback *(BDPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message) {
        StrongSelf;
        if (!self) {
            return nil;
        }
        @synchronized (self) {
            [self logLevel:level fileName:fileName funcName:funcName line:line message:message];
        }
        return self;
    };
}

- (void)logLevel:(BDPLogLevel)level
        fileName:(const char* _Nullable)fileName
        funcName:(const char* _Nullable)funcName
            line:(int)line
         message:(NSString *)message {
    NSString *logContent = [NSString stringWithFormat:@"%@. %@", message ?: @"", self.exLogInfo];
    _ECOInfraFoundationLog(level, self.logTag, nil, fileName ?: self.fileName.UTF8String, funcName ?: self.funcName.UTF8String, line ?: (int)self.line, logContent);
}

- (NSString *)logTag {
    return [NSString stringWithFormat:@"API_%@", self.apiName];
}

/*----------------------------------------------------------*/
//                         监控(待补充)
/*----------------------------------------------------------*/

@end

/*----------------------------------------------------------*/
// 为了将原 API 调用暴露给 Swift，需要提供一个「哑」的 APICallback
// 外部仅提供 JSSDK API 携带的入参，给出 API 执行结果, 使用 `copyCallbackData` 取出数据
//
// 注意，因包含状态切换，使用此 DummyCallback 接收数据后
// 必须在 callback 位置时调用一次 `copyCallbackData` 将 API 结果取出
/*----------------------------------------------------------*/
@implementation OPAPIDummyCallback

- (instancetype)init
{
    self = [super initWithCallback:nil engine:nil fileName:nil funcName:nil line:0];
    if (self) {
        self.callbackData = NSMutableDictionary.dictionary;
        self.exLogInfo = NSMutableString.string;
    }
    return self;
}

- (NSDictionary *)copyCallbackData {
    @synchronized (self) {
        self.invoked = true;
        return self.callbackData.copy;
    }
}

/// 重写 parseAPI Name，因为此情况下无 API name 传入, 无法 parse 成功
- (void)parseApiName {
}

@end

#pragma clang diagnostic push
