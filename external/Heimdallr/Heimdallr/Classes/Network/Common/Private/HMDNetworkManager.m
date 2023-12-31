//
//  HMDUploadManager.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/7.
//

#import "HMDNetworkManager.h"
#import "HMDNetworkProtocol.h"
#import "HMDURLSessionManager.h"
#import "HMDDynamicCall.h"
#import "HMDInjectedInfo.h"
#import "HMDALogProtocol.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetworkReqModel.h"
#import "NSArray+HMDJSON.h"
#import "NSDictionary+HMDJSON.h"
#import "NSData+HMDGzip.h"
#import "HMDNetworkInjector.h"
#import "NSString+HMDSafe.h"
#if RANGERSAPM
#import "NSData+HMDDataDecorator.h"
#else
#import <BDDataDecorator/NSData+DataDecorator.h>
#endif
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"

@interface HMDNetworkManager()

@property (nonatomic,strong) id<HMDNetworkProtocol> ttnetManager;
@property (nonatomic,strong) id<HMDNetworkProtocol> urlsessionManager;
@property (atomic, strong) id<HMDNetworkProtocol> customManager;

@end

@implementation HMDNetworkManager

static HMDNetworkManager *instance = nil;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDNetworkManager alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        Class ttnetUploadClass = NSClassFromString(@"HMDTTNetManager");
        if (ttnetUploadClass && [ttnetUploadClass conformsToProtocol:@protocol(HMDNetworkProtocol)]) {
            self.ttnetManager = [ttnetUploadClass new];
        }
        self.urlsessionManager = [HMDURLSessionManager new];
    }
    return self;
}

- (id<HMDNetworkProtocol>)validManager {
    if ([self useCustomNetworkManager]) {
        return self.customManager;
    }
    if (self.ttnetManager && ![HMDInjectedInfo defaultInfo].useURLSessionUpload) {
        if (DC_IS(DC_OB(self.ttnetManager, isChromium), NSNumber).boolValue) {
            return self.ttnetManager;
        }
    }
    return self.urlsessionManager;
}

- (void)setCustomNetworkManager:(id<HMDNetworkProtocol>)manager {
    self.customManager = manager;
}

- (BOOL)useCustomNetworkManager {
    return self.customManager != nil;
}

- (void)asyncRequestWithModel:(HMDNetworkReqModel *)model callback:(HMDNetworkJSONFinishBlock)callback {
    if ([[self validManager] respondsToSelector:@selector(asyncRequestWithModel:callback:)]) {
        [self handleRequestModel:model];
        [[self validManager] asyncRequestWithModel:model callback:callback];
    }
    [self asyncRequestWithModel:model callBackWithResponse:^(NSError *error, id data, NSURLResponse *response) {
        NSMutableDictionary *rs = [NSMutableDictionary dictionary];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpResponse statusCode];
            NSDictionary *headerFields = [httpResponse allHeaderFields];
            [rs setValue:@(statusCode) forKey:@"status_code"];
            //ran is the key for aes
            NSString *ran = [[httpResponse allHeaderFields] hmd_objectForInsensitiveKey:@"ran"];
            if (ran && [ran isKindOfClass:NSString.class]) [rs setValue:ran forKey:@"ran"];
            //x-tt-logid is the id for event trace
            NSString *xTTLogid = [headerFields objectForKey:@"x-tt-logid"];
            [rs setValue:xTTLogid forKey:@"x-tt-logid"];
#ifdef RANGERSAPM
            //X-Auth-Block is the result for aid auth
            BOOL authBlockState = [headerFields hmd_hasKey:@"X-Auth-Block"];
            if (authBlockState) {
                [rs setValue:@([headerFields hmd_boolForKey:@"X-Auth-Block"]) forKey:@"X-Auth-Block"];
            }
#endif
        } else if (response && hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@", @"Heimdallr HTTP response is not NSHTTPURLResponse");
        }
        if (!error) {
            @try {
                NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                [rs setValue:jsonObj forKey:@"result"];
                if (response) {
                    [rs setValue:@YES forKey:@"has_response"];
                }
            } @catch (NSException *exception) {
            } @finally {
            }
        }
        if(callback) {
            callback(error, [rs copy]);
        }
    }];
}

- (void)asyncRequestWithModel:(HMDNetworkReqModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse {
    [self handleRequestModel:model];
    [[self validManager] asyncRequestWithModel:model callBackWithResponse:callBackWithResponse];
}

- (void)uploadWithModel:(HMDNetworkUploadModel *)model callback:(HMDNetworkJSONFinishBlock)callback {
    if ([[self validManager] respondsToSelector:@selector(uploadWithModel:callback:)]) {
        [[self validManager] uploadWithModel:model callback:callback];
    }
    [self uploadWithModel:model callBackWithResponse:^(NSError *error, id data, NSURLResponse *response) {
        NSMutableDictionary *rs = [NSMutableDictionary dictionary];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            NSDictionary *httpHeader = [(NSHTTPURLResponse *)response allHeaderFields];
            [rs setValue:@(statusCode) forKey:@"status_code"];
            if (httpHeader != nil) {
                NSString *logid = [httpHeader hmd_stringForKey:@"x-tt-logid"];
                if (logid != nil) {
                    [rs setValue:logid forKey:@"http_header_logid"];
                }
            }
        } else if (response && hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@", @"Heimdallr HTTP response is not NSHTTPURLResponse");
        }
        if (!error) {
            @try {
                NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                [rs setValue:jsonObj forKey:@"result"];
                if (response) {
                    [rs setValue:@YES forKey:@"has_response"];
                }
            } @catch (NSException *exception) {
            } @finally {
            }
        }
        if(callback) {
            callback(error,[rs copy]);
        }
    }];
}

- (void)uploadWithModel:(HMDNetworkUploadModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse {
    [[self validManager] uploadWithModel:model callBackWithResponse:callBackWithResponse];
}

- (void)handleRequestModel:(HMDNetworkReqModel *)model {
    if (model.isFromHermas) {
        [self logMemoryWithModel:model];
        return;
    }
    // 目前hermas传过来的数据是已经处理过的了，不需要再处理，打印下内存日志即可
    NSMutableDictionary *fixedHeaderField = [NSMutableDictionary dictionaryWithDictionary:model.headerField];
    id<HMDJSONObjectProtocol> params = model.params;
    NSData *sendingData;
    
    if ([params hmd_isValidJSONObject]) {
        sendingData = [params hmd_jsonDataWithOptions:kNilOptions error:nil];
    }
#ifdef DEBUG
    // 无法转换成NSData的params在DEBUG下报警
    else if (params && ![params hmd_isValidJSONObject]) {
        NSAssert(NO, @"The parameters of network request cannot be serialized! please check the format of the parameters.");
    }
#endif
    
    NSData *compressedData = [sendingData hmd_gzipDeflate];
    [fixedHeaderField setValue:@"gzip" forKey:@"Content-Encoding"];
    
    NSData *bodyData = compressedData;
    if (model.needEcrypt && compressedData != nil) {
        HMDNetEncryptBlock encryptBlock = [HMDNetworkInjector sharedInstance].encryptBlock;
        if(encryptBlock != nil) {
            NSData *resultData = encryptBlock(compressedData);
            if(resultData != nil) {
                bodyData = resultData;
                [fixedHeaderField setValue:@"application/octet-stream;tt-data=a" forKey:@"Content-Type"];    // 没有会失败
            }
        }
#if !EMBED
        else {
#if RANGERSAPM
            NSData *resultData = [compressedData hmd_dataByDecorated];
#else
            NSData *resultData = [compressedData bd_dataByDecorated];
#endif
            if (resultData) {
                bodyData = resultData;
                [fixedHeaderField setValue:@"application/octet-stream;tt-data=a" forKey:@"Content-Type"];    // 没有会失败
            }
        }
#endif
    }
    model.postData = bodyData;
    model.params = nil;
    model.headerField = fixedHeaderField;
    [self logMemoryWithModel:model];
}

- (void)logMemoryWithModel:(HMDNetworkReqModel *)model {
    if (hmd_log_enable()) {
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        float appMemory = memoryBytes.appMemory/HMD_MB;
        NSString *networkType = NSStringFromClass([[self validManager] class]);
        NSString *contentType = [model.headerField objectForKey:@"Content-Type"];
        
        NSString *simpleURL = model.requestURL;
        NSRange range = [model.requestURL rangeOfString:@"?"];
    
        if(range.length > 0 && range.location != NSNotFound && (range.length + range.location) <= [model.requestURL length]){
            simpleURL = [model.requestURL hmd_substringToIndex:range.location];
        }
        
        NSString *networkLog = [NSString stringWithFormat:@"net_type：%@，uri：%@, body size:%lubyte, is_encrypt:%d, body type:%@, app total memory usage:%fMB", networkType, simpleURL, (unsigned long)model.postData.length, model.needEcrypt, contentType, appMemory];
        
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@",networkLog);
    }
}

@end
