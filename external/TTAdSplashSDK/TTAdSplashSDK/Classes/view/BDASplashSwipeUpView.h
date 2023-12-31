//
//  BDASplashSwipeUpView.h
//  TTAdSplashSDK
//
//  Created by lixiaowei on 2020/12/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 上滑跳过视图
/// 具体 UI 可以参考：https://bytedance.feishu.cn/docs/doccn19xmXXkkIHtDVUqsIMCzYg#cZsIlC
@interface BDASplashSwipeUpView : UIView

/// 功能：更新提示文案和背景色
/// 注意：需要在调用该函数之前设置好 frame。
/// 布局方式：按照外面给的 frame 进行水平居中布局，如果放不下，text 默认 ... 展示，如果布局后的 size 比 frame.size 小，则会自动缩放，因此调用方在调用前可以给一个最大 size，调用后一般需要调整 center 位置。
/// @param text 提示文案
/// @param bgColor 背景色，如果为空则透明
- (void)updateText:(NSString *)text bgColor:(UIColor *)bgColor;

@end

NS_ASSUME_NONNULL_END
