//
//  CJPayGeneralAbilityManager.m
//  Aweme
//
//  Created by ByteDance on 2023/3/25.
//

#import "CJPayGeneralAbilityManager.h"
#import "CJPayGeneralAbilityService.h"
#import "CJPayGeneralParamsService.h"
#import "CJPayProtocolViewService.h"
#import "CJPaySDKMacro.h"

@interface CJPayGeneralAbilityManager() <CJPayGeneralAbilityService>

@property (nonatomic, copy) NSDictionary *actionNames;

@end

@implementation CJPayGeneralAbilityManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayGeneralAbilityService)
})

+ (instancetype)defaultService {
    static CJPayGeneralAbilityManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayGeneralAbilityManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.actionNames = @{
            @"open_protocol":@(CJPayGeneralAbilityActionShowProtocol),
            @"get_dev_info":@(CJPayGeneralAbilityActionReturnGeneralParams),
        };
    }
    return self;
}

- (void)i_wekeByGeneralAbility:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    NSString *actionName = [params cj_stringValueForKey:@"cjpay_action"];
    NSInteger action = [self.actionNames cj_integerValueForKey:actionName];
    
    switch (action) {
        case CJPayGeneralAbilityActionShowProtocol: {
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayProtocolViewService)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"展示协议能力未包含" from:delegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayProtocolViewService) i_showProtocolDetail:params delegate:delegate];
            break;
        }
        case CJPayGeneralAbilityActionReturnGeneralParams: {
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayGeneralParamsService)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"获取通参能力未包含" from:delegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayGeneralParamsService) i_getGeneralParamsWithQuery:params delegate:delegate];
            break;
        }
        default:
            break;
    }
}

- (void)p_onResponseError:(CJPayErrorCode)errorCode errorDesc:(NSString *)errorDesc from:(id<CJPayAPIDelegate>)delegate {
    if (delegate) {
        CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
        baseResponse.scene = CJPaySceneGeneralAbilityService;
        baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{@"errorDesc": CJString(errorDesc)}];
        baseResponse.data = @{@"code": @"",
                              @"msg": @"参数异常",
                              @"data":@""};
        [delegate onResponse:baseResponse];
    }
}

@end
