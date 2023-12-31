//
//  CJPayNestingLynxCardManager.m
//  Aweme
//
//  Created by ByteDance on 2023/5/6.
//

#import "CJPayNestingLynxCardManager.h"
#import "CJPayNestingLynxCardViewController.h"
#import "CJPayUIMacro.h"

@interface CJPayNestingLynxCardManager ()

@end

@implementation CJPayNestingLynxCardManager

+ (instancetype)defaultService {
    static CJPayNestingLynxCardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayNestingLynxCardManager alloc] init];
    });
    return manager;
}

- (void)openSchemeByNtvVC:(NSString *)scheme fromVC:(UIViewController *)fromVC withInfo:(NSDictionary *)sdkInfo completion:(nonnull void (^)(BOOL isOpenSuccess, NSDictionary * ext))completion {
    [self trackerWithSdkInfo:sdkInfo];
    CJPayNestingLynxCardViewController *vc = [[CJPayNestingLynxCardViewController alloc] initWithSchema:scheme data:[sdkInfo cj_dictionaryValueForKey:@"data"]];
    vc.eventBlock = ^(BOOL isOpenSuccess, NSDictionary * _Nonnull ext) {
        if (!isOpenSuccess) {
            [CJTracker event:@"walllet_rd_open_cjlynxcard_fail" params:@{}];
            CJ_CALL_BLOCK(completion, isOpenSuccess, ext);
        }
    };
    [vc presentWithNavigationControllerFrom:fromVC useMask:NO completion:nil];
}

- (void)trackerWithSdkInfo:(NSDictionary *)sdkInfo {
    NSString *type = [sdkInfo cj_stringValueForKey:@"type"];
    if ([type isEqualToString:@"retain_dialog"]) {
        [CJTracker event:@"wallet_rd_try_open_lynx_retain" params:@{}];
    }
}

@end
