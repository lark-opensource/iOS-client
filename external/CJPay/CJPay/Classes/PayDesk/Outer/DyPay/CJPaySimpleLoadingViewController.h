//
//  CJPaySimpleLoadingViewController.h
//  Aweme
//
//  Created by ByteDance on 2023/8/7.
//

#import "CJPayFullPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * CJPaySimpleLoadingViewController是一个占位用的ViewController，在唤端支付冷启优化中引入。
 * 用途：将其设置为抖音TabBarController第一个NavigationController的默认VC，加速唤端支付收银台的拉起速度。
 * 引入原因：是在将抖音首页替换为支付首页时，会有一个短暂的黑屏现象，所以必须将这个占位VC的背景颜色与CJPayOuterBaseViewController保持一致，这样才不会让用户感觉有闪动的现象。
 * 注意：CJPaySimpleLoadingViewController尽量不要放置多余的代码，仅仅设置背景颜色和NavigationBar隐藏。
 */
@interface CJPaySimpleLoadingViewController : CJPayFullPageBaseViewController

@end

NS_ASSUME_NONNULL_END
