//
//  CJPayMemVerifyManager.m
//  CJPay
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPayMemVerifyManager.h"
#import "CJPayUIMacro.h"
#import "CJPayMemVerifyItem.h"
#import "CJPayMemVerifyItemPassword.h"

@interface CJPayMemVerifyManager()

@property (nonatomic, copy) NSDictionary *verifyItemConfig;

@property (nonatomic, strong) NSMutableDictionary *trackParams;

@end

@implementation CJPayMemVerifyManager

- (void)beginMemVerifyWithType:(CJPayVerifyType)type params:(NSDictionary *)params fromVC:(UIViewController *)fromVC completion:(void(^)(CJPayMemVerifyResultModel *resultModel))completedBlock {
    NSDictionary *trackDict = [params cj_dictionaryValueForKey:@"track_info"];
    if ([trackDict isKindOfClass:NSDictionary.class] && trackDict.count > 0) {
        [self.trackParams addEntriesFromDictionary:trackDict];
    }
    
    CJPayMemVerifyItem *item = [self p_getMemVerifyItemWithType:type];
    item.verifyManager = self;
    [item verifyWithParams:params fromVC:fromVC completion:completedBlock];
}

- (CJPayMemVerifyItem *)p_getMemVerifyItemWithType:(CJPayVerifyType)type {
    CJPayMemVerifyItem *curItem = [self p_getSpecificVerifyType:type];
    return curItem;
}

- (NSDictionary *)verifyItemConfig {
    if (!_verifyItemConfig) {
        _verifyItemConfig = @{
            @(CJPayVerifyTypePassword) : [CJPayMemVerifyItemPassword new]
        };
    }
    return _verifyItemConfig;
}

- (nullable CJPayMemVerifyItem *)p_getSpecificVerifyType:(CJPayVerifyType)type {
    
    if ([self.verifyItemConfig objectForKey:@(type)]) {
        return (CJPayMemVerifyItem *)[self.verifyItemConfig objectForKey:@(type)];
    }
    CJPayLogAssert(NO, @"不能根据Type拿到类名称");
    return nil;
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    [trackParams addEntriesFromDictionary:[self.trackParams copy]];
    [CJTracker event:event params:[trackParams copy]];
}

- (NSMutableDictionary *)trackParams {
    if (!_trackParams) {
        _trackParams = [NSMutableDictionary dictionary];
    }
    return _trackParams;
}

@end
