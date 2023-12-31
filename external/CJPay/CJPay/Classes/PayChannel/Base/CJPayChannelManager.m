//
//  CJPayChannelManager.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJPayChannelManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySDKMacro.h"
#import "CJPayChannelManagerModule.h"
#import "CJPayPrivacyMethodUtil.h"

@interface CJPayChannelManager()<CJPayChannelManagerModule>

@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, Class<CJPayChannelProtocol>> *payChannelClsDict;
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, id<CJPayChannelProtocol>> *payChannelObjDict;

@end

@implementation CJPayChannelManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayChannelManagerModule)
})

+ (instancetype)sharedInstance {
    static CJPayChannelManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayChannelManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.payChannelObjDict = [NSMutableDictionary dictionary];
        self.payChannelClsDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerChannelClass:(Class<CJPayChannelProtocol>)channelCls channelType:(CJPayChannelType)channelType {
    NSMutableDictionary<id<NSCopying>, Class<CJPayChannelProtocol>> *channelDic = self.payChannelClsDict;
    BOOL isChannelRegister = [channelDic objectForKey:@(channelType)] != nil;
    BOOL isChannelClsConfromsChannelProtocol = [channelCls conformsToProtocol:@protocol(CJPayChannelProtocol)];
    if (!isChannelRegister && isChannelClsConfromsChannelProtocol) {
        [channelDic btd_setObject:channelCls forKey:@(channelType)];
    } else {
        [CJMonitor trackService:@"wallet_rd_paychannel_class_register" extra:@{
            @"channelClsDuplicateRegister" : isChannelRegister ? @"1" : @"0",
            @"channelClsProtocolIllegal" : isChannelClsConfromsChannelProtocol ? @"0" : @"1"
        }];
    }
}

- (id<CJPayChannelProtocol>)getChannelObjectWithType:(CJPayChannelType)channelType {
    id channelObject = [self.payChannelObjDict objectForKey:@(channelType)];
    if (channelObject && [channelObject conformsToProtocol:@protocol(CJPayChannelProtocol)]) {
        return channelObject;
    }
    
    Class channelCls = [self.payChannelClsDict objectForKey:@(channelType)];
    
    BOOL isChannelClsConfromsChannelProtocol = [channelCls conformsToProtocol:@protocol(CJPayChannelProtocol)];
    
    if (isChannelClsConfromsChannelProtocol) {
        channelObject = [[channelCls alloc] init];
        [self.payChannelObjDict btd_setObject:channelObject forKey:@(channelType)];
    } else {
        [CJMonitor trackService:@"wallet_rd_paychannel_instance_get" extra:@{
            @"channelClsUnRegister" : (channelCls == nil) ? @"1" : @"0",
            @"channelClsProtocolIllegal" : @"1"
        }];
    }
    
    return channelObject;
}

- (void)removeChannelObjectWithType:(CJPayChannelType)channelType {
    if (self.payChannelObjDict && self.payChannelObjDict.count > 0 && [self.payChannelObjDict objectForKey:@(channelType)]) {
        [self.payChannelObjDict removeObjectForKey:@(channelType)];
    }
}

/**
 *  判断 URL 收银台是否可以处理
 *
 *  @param URL 获取的 URL
 *
 *  @return 如果可以处理返回 YES，反之为 NO
 */
- (BOOL)canProcessWithURL:(NSURL *)URL {
    
    __block BOOL canPay = NO;
    __block CJPayChannelType payType = 0;
    __block NSDictionary *extParams = nil;
    [[self.payChannelObjDict copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        CJPayBasicChannel *payChannel = (CJPayBasicChannel *)obj;
        if ([payChannel canProcessWithURL:URL]) {
            payType = payChannel.channelType;
            extParams = [payChannel.dataDict copy];
            canPay = YES;
        }
    }];
    CJPayLogInfo(@"cjpay_sdk_get_app_callBack type:schema method:%@ canProcess:%@", @(payType).stringValue, @(canPay).stringValue);
    [self p_trackWithEventName:@"cjpay_sdk_get_app_callBack" params:@{@"type":@"url",@"method":@(payType),@"canProcess":@(canPay)} extParams:extParams];
    return canPay;
}

- (BOOL)canProcessUserActivity:(NSUserActivity *)activity {
    __block BOOL canPay = NO;
    __block CJPayChannelType payType = 0;
    __block NSDictionary *extParams = nil;
    [[self.payChannelObjDict copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        CJPayBasicChannel *payChannel = (CJPayBasicChannel *)obj;
        if ([payChannel canProcessUserActivity:activity]) {
            payType = payChannel.channelType;
            extParams = [payChannel.dataDict copy];
            canPay = YES;
        }
    }];
    CJPayLogInfo(@"cjpay_sdk_get_app_callBack type:userActivity method:%@ canProcess:%@", @(payType).stringValue, @(canPay).stringValue);
    [self p_trackWithEventName:@"cjpay_sdk_get_app_callBack" params:@{@"type":@"userActivity",@"method":@(payType),@"canProcess":@(canPay)} extParams:extParams];
    return canPay;
}

- (void)payActionWithType:(CJPayChannelType)type
                 dataDict:(NSDictionary *)dataDict
          completionBlock:(CJPayCompletion)completionBlock {
    
    CJPayBasicChannel *payChannel = [self getChannelObjectWithType:type];
    if (payChannel) {
        [CJPayPrivacyMethodUtil injectCert:[NSString stringWithFormat:@"bpea-cjpaychannel_%tu_payaction", type]];
        [payChannel payActionWithDataDict:dataDict completionBlock:completionBlock];
        [CJPayPrivacyMethodUtil clearCert];
    } else {
        //暂不支持该支付类型
        CJ_CALL_BLOCK(completionBlock, payChannel.channelType, CJPayResultTypeUnInstall, 0);
    }
}

#pragma mark - service
- (NSString *)i_wxH5PayReferUrlStr {
    return self.h5PayReferUrl;
}

- (void)i_registerWXUniversalLink:(NSString *)wxUniversalLink {
    self.wxUniversalLink = wxUniversalLink;
}

- (void)i_registerWXH5PayReferUrlStr:(NSString *)urlstr {
    self.h5PayReferUrl = urlstr;
}

- (BOOL)i_canProcessURL:(NSURL *)url {
    CJPayLogInfo(@"[CJPayChannelManager i_canProcessURL:%@]", CJString(url.absoluteString));
    return [self canProcessWithURL:url];
}

- (BOOL)i_canProcessUserActivity:(NSUserActivity *)userActivity {
    CJPayLogInfo(@"[CJPayChannelManager i_canProcessUserActivity]");
    return [self canProcessUserActivity:userActivity];
}

- (void)i_payActionWithChannel:(CJPayChannelType)type dataDict:(NSDictionary *)dataDict completionBlock:(void (^)(CJPayChannelType, CJPayResultType, NSString *))completionBlock {
    [self payActionWithType:type dataDict:dataDict completionBlock:^(CJPayChannelType channelType, CJPayResultType resultType, NSString *errorCode) {
        CJ_CALL_BLOCK(completionBlock, channelType, resultType, errorCode);
        
        [self removeChannelObjectWithType:channelType];
    }];
}

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    NSNumber *channel = [dictionary cj_objectForKey:@"pay_channel"];
    if ([channel unsignedIntValue] == CJPayChannelTypeWXH5 &&
            [dictionary cj_stringValueForKey:@"refer"] &&
            [dictionary cj_stringValueForKey:@"refer"].length > 0) {
        [self i_registerWXH5PayReferUrlStr:[dictionary cj_stringValueForKey:@"refer"]];
    }
    
    [self payActionWithType:[channel unsignedIntValue]
                   dataDict:dictionary
            completionBlock:^(CJPayChannelType channelType, CJPayResultType resultType, NSString *errorCode) {
        CJPayErrorCode returnCode = CJPayErrorCodeFail;
        NSString *errorMsg = nil;
        NSNumber *subCode = nil;
        NSString *subErrMsg = nil;
        switch (resultType) {
            case CJPayResultTypeCancel:
                returnCode = CJPayErrorCodeCancel;
                errorMsg = @"用户取消支付";
                break;
            case CJPayResultTypeFail:
                returnCode = CJPayErrorCodeFail;
                errorMsg = @"支付失败";
                break;
            case CJPayResultTypeSuccess:
                returnCode = CJPayErrorCodeSuccess;
                errorMsg = @"支付成功";
                break;
            case CJPayResultTypeProcessing:
                returnCode = CJPayErrorCodeProcessing;
                errorMsg = @"正在处理中，请查询商户订单列表中订单的支付状态";
                break;
            case CJPayResultTypeBackToForeground:
                if ([dictionary cj_boolValueForKey:@"use_visible_callback"]) {
                    returnCode = CJPayErrorCodeBackToForground;
                } else {
                    returnCode = CJPayErrorCodeFail;
                }
                errorMsg = @"应用从后台手动返回，支付结果未知";
                subCode = @(CJPayErrorCodeBackToForground);
                subErrMsg = errorMsg;
                break;
            default:
                break;
        }
        
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = CJPaySceneEcommercePay;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:returnCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
        
        NSMutableDictionary *data = @{
            @"sdk_code": @(returnCode),
            @"sdk_msg": CJString(errorMsg)
        }.mutableCopy;
        NSDictionary *newCreateOrderResponse = [dictionary cj_dictionaryValueForKey:@"create_order_response"];
        if (Check_ValidDictionary(newCreateOrderResponse)) {
            [data addEntriesFromDictionary:@{@"create_order_response" : newCreateOrderResponse}];
        }
        if (Check_ValidString(subErrMsg) && subCode) {
            [data addEntriesFromDictionary:@{
                @"sdk_sub_code": subCode,
                @"sdk_sub_msg": subErrMsg
            }];
        }
        apiResponse.data = data.copy;
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        }

    }];
    return YES;
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params extParams:(NSDictionary *)extParams {
    NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    [mutableParams addEntriesFromDictionary:extParams];
    [CJTracker event:eventName params:[mutableParams copy]];
}

@end
