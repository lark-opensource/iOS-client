//
//  CJPaySignView.h
//  Pods
//
//  Created by chenbocheng on 2022/7/11.
//

#import <Foundation/Foundation.h>

#import "CJPaySignModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayQuerySignInfoResponse;
@class CJPaySignOnlyQuerySignTemplateResponse;
@class CJPayStyleButton;
typedef NS_ENUM(NSInteger, CJPaySignViewType) {
    CJPaySignViewTypeSignAndPay,  // 签约并支付
    CJPaySignViewTypeSignOnly,    // 独立签约
};

@interface CJPaySignView : UIView

@property (nonatomic, copy) void(^confirmActionBlock)(void);
@property (nonatomic, copy) void(^changePayMethodBlock)(void);

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton;
@property (nonatomic, strong, readonly) UILabel *deductMethodLabel;

@property (nonatomic, assign) CJPaySignViewType viewType;

- (instancetype)initWithViewType:(CJPaySignViewType)viewType;
- (void)updateWithSignModel:(CJPaySignModel *)model;

@end

NS_ASSUME_NONNULL_END
