//
//  CJPayBrandPromoteABTestManager.m
//  Pods
//
//  Created by 易培淮 on 2021/6/9.
//

#import "CJPayBrandPromoteABTestManager.h"
#import "CJPaySettingsManager.h"

@implementation CJPayBrandPromoteABTestManager

+ (instancetype)shared
{
    static CJPayBrandPromoteABTestManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayBrandPromoteABTestManager alloc] init];
    });
    return manager;
}

- (BOOL) isHitTest {
    if (self.model && self.model.showNewLoading) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Getter

- (CJPayBrandPromoteModel *)model {
    if (!_model) {
        _model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
    }
    return _model;
}

@end
