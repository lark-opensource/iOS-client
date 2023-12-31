//
//  CJPayChooseDyPayMethodViewController.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/19.
//

#import <UIKit/UIKit.h>
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayChooseDyPayMethodViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, assign) CGFloat height; //调用方可指定选卡页高度
@property (nonatomic, copy) void(^didSelectedBlock)(CJPayDefaultChannelShowConfig *selectConfig, UIView *loadingView); //”选择支付方式“事件回调

- (instancetype)initWithManager:(CJPayChooseDyPayMethodManager *)manager;
- (void)refreshPayMethodSelectStatus:(CJPayDefaultChannelShowConfig *)config;

@end

NS_ASSUME_NONNULL_END
