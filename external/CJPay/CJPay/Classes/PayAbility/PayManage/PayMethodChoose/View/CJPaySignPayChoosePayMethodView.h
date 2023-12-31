//
//  CJPaySignPayChoosePayMethodView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPaySignPayChoosePayMethodModel;
@class CJPayDefaultChannelShowConfig;

typedef void (^CJPayDidSelectedBlock)(CJPayDefaultChannelShowConfig *selectedConfig, UIView *loadingView);
@interface CJPaySignPayChoosePayMethodView : UIView

@property (nonatomic, strong) CJPayDidSelectedBlock didSelectedBlock;

- (instancetype)initWithPayMethodViewModel:(CJPaySignPayChoosePayMethodModel *)model;

- (void)updatePayMethodViewBySelectConfig:(CJPayDefaultChannelShowConfig *)selectConfig;

@end

NS_ASSUME_NONNULL_END
