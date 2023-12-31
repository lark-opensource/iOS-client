//
//  CJPayProtocolViewManager.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/23.
//

#import "CJPayProtocolViewManager.h"

#import "CJPayMemProtocolListRequest.h"
#import "CJPayMemProtocolListResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayProtocolDetailViewController.h"
#import "CJPayMemAgreementModel.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayQuickPayUserAgreement.h"
#import "CJPayProtocolViewService.h"

@interface CJPayProtocolViewManager() <CJPayProtocolViewService>

@end

@implementation CJPayProtocolViewManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayProtocolViewService)
})

+ (instancetype)defaultService {
    static CJPayProtocolViewManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayProtocolViewManager alloc] init];
    });
    return manager;
}

+ (void)fetchProtocolListWithParams:(NSDictionary *)params completion:(nonnull void (^)(NSError * _Nonnull, CJPayMemProtocolListResponse * _Nonnull))completion
{
    [CJPayMemProtocolListRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPayMemProtocolListResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (CJPayHalfPageBaseViewController *)createProtocolViewController:(NSArray<CJPayQuickPayUserAgreement *> *)quickAgreeList protocolModel:(CJPayCommonProtocolModel *)protocolModel  {
    if (quickAgreeList.count > 1) {
        CJPayProtocolListViewController *vc = [CJPayProtocolListViewController new];
        vc.userAgreements = quickAgreeList;
        vc.animationType = HalfVCEntranceTypeFromBottom;
        vc.showContinueButton = NO;
        vc.isSupportClickMaskBack = YES;
        vc.isShowTitleNubmer = NO;
        if (protocolModel.protocolDetailContainerHeight) {
            vc.height = [protocolModel.protocolDetailContainerHeight floatValue];
        }
        return vc;
    } else {
        CJPayQuickPayUserAgreement *agreement = [quickAgreeList cj_objectAtIndex:0];
        CJPayProtocolDetailViewController *vc = [CJPayProtocolDetailViewController new];
        vc.url = agreement.contentURL;
        vc.navTitle = agreement.title;
        vc.showContinueButton = NO;
        vc.animationType = HalfVCEntranceTypeFromBottom;
        vc.isSupportClickMaskBack = YES;
        vc.isShowTitleNubmer = NO;
        if (protocolModel.protocolDetailContainerHeight) {
            vc.height = [protocolModel.protocolDetailContainerHeight floatValue];
        }
        return vc;
    }
}

- (void)p_showProtocolDetail:(NSDictionary *)params completionBlock:(CJPayProtocolCallBack)completionBlock {
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    
    CJPayCommonProtocolModel *protocolModel = [[CJPayCommonProtocolModel alloc] init];
    NSMutableArray<CJPayMemAgreementModel *> *mutableAgreements = [[NSMutableArray alloc] init];
    [[params cj_arrayValueForKey:@"protocol_list"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayMemAgreementModel *agreementModel = [[CJPayMemAgreementModel alloc] init];
        agreementModel.url = [obj cj_stringValueForKey:@"template_url"];
        agreementModel.name = [obj cj_stringValueForKey:@"name"];
        agreementModel.isChoose = NO;
        [mutableAgreements btd_addObject:agreementModel];
    }];
    protocolModel.agreements = [mutableAgreements copy];
    
    
    NSMutableArray<CJPayQuickPayUserAgreement *> *agreements = [NSMutableArray array];
    [protocolModel.agreements enumerateObjectsUsingBlock:^(CJPayMemAgreementModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [agreements addObject:[obj toQuickPayUserAgreement]];
    }];
    CGFloat height = [params cj_floatValueForKey:@"height"];
    if (height > 0.f) {
        protocolModel.protocolDetailContainerHeight = @(height);
    }

    NSArray<CJPayQuickPayUserAgreement *> *quickAgreeList = [agreements copy];
    CJPayHalfPageBaseViewController *tmpVC = [CJPayProtocolViewManager createProtocolViewController:quickAgreeList protocolModel:protocolModel];
    if (![[params cj_stringValueForKey:@"close_icon"] isEqualToString:@"back"]) {
        [tmpVC useCloseBackBtn];
    }
    tmpVC.closeActionCompletionBlock = ^(BOOL finish) {
        if (finish) {
            CJ_CALL_BLOCK(completionBlock);
        }
    };
    [tmpVC showMask:YES];
    
    if ([topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:tmpVC animated:YES];
    } else {
        [tmpVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
    }
}

#pragma - mark wake by universalPayDesk

- (void)i_showProtocolDetail:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [self p_showProtocolDetail:params completionBlock:^{
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = CJPaySceneGeneralAbilityService;
        apiResponse.data = @{
            @"msg": @"protocol_closed",
            @"code": @"",
            @"data": @{}
        };
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        }
    }];
}

@end
