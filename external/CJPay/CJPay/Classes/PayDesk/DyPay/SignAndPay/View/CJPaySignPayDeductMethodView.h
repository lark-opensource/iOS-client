//
//  CJPaySignPayDeductMethodView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPaySignPayModel;
@class CJPayDefaultChannelShowConfig;
@interface CJPaySignPayDeductMethodView : UIView

@property (nonatomic, copy) void (^payMethodClick)(void);

- (void)updateDeductMethodViewWithModel:(CJPaySignPayModel *)model;

- (void)updateDeductMethodViewWithConfig:(CJPayDefaultChannelShowConfig *)defaultConfig;

@end

NS_ASSUME_NONNULL_END
