//
//  CJPaySignPayDeductDetailView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayDescView;
@class CJPaySignPayDeductMethodView;
@class CJPaySignPayModel;
@class CJPayDefaultChannelShowConfig;

@interface CJPaySignPayDeductDetailView : UIView

@property (nonatomic, assign) BOOL isNewUser; // 判断是不是新用户，新用户隐藏支付方式部分UI

- (void)updateDeductDetailViewWithModel:(CJPaySignPayModel *)model payMethodClick:(void (^)(void))payMethodClick;

- (void)updateDeductMethodView:(CJPayDefaultChannelShowConfig *)defaultConfig;

@end

NS_ASSUME_NONNULL_END
