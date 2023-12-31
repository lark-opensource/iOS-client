//
//  CJPaySignPayView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayHeaderView;
@class CJPaySignPayModel;
@class CJPayChooseDyPayMethodManager;
@class CJPayDefaultChannelShowConfig;
@class CJPayStyleButton;

@interface CJPaySignPayView : UIView

@property (nonatomic, assign) BOOL isNewUser;

@property (nonatomic, copy) void(^confirmBtnClickBlock)(CJPayStyleButton *loadingView);

@property (nonatomic, copy) void(^payMethodClick)(void);

@property (nonatomic, copy) void(^trackerBlock)(NSString *eventName, NSDictionary *params);

// 用来修改详情页展示的支付方式
- (void)updateDeductMethodView:(CJPayDefaultChannelShowConfig *)defaultConfig buttonTitle:(nullable NSString *)buttonTitle;

- (void)updateInitialViewWithSignPayModel:(CJPaySignPayModel *)model;

- (BOOL)obtainSwitchStatus;

@end

NS_ASSUME_NONNULL_END
