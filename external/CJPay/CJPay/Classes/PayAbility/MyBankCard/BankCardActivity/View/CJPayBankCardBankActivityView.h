//
//  CJPayBankCardBankActivityView.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayBankActivityInfoModel;

@interface CJPayBankCardBankActivityView : UIView

@property (nonatomic, copy) void(^didSelectedBlock)(CJPayBankActivityInfoModel *model);
@property (nonatomic, copy) void(^buttonClickBlock)(CJPayBankActivityInfoModel *model);

- (void)bindBankActivityModel:(CJPayBankActivityInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
