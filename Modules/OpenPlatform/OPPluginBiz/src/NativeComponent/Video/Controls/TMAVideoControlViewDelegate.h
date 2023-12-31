//
//  TMAVideoControlViewDelegate.h
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/2.
//

#ifndef TMAVideoControlViewDelegate_h
#define TMAVideoControlViewDelegate_h


#endif /* TMAVideoControlViewDelegate_h */

@class TMAVideoControlView, TMAVideoLockButton;
@protocol TMAVideoControlViewDelegate <NSObject>

@optional
/** 返回按钮事件 */
- (void)tma_controlViewBackAction;
/** 播放按钮事件 */
- (void)tma_controlView:(UIView *)controlView playAction:(UIButton *)sender isCenter:(BOOL)isCenter;
/** 全屏按钮事件 */
- (void)tma_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender;
/** 锁定屏幕方向按钮事件 */
- (void)tma_controlView:(UIView *)controlView isLocked:(BOOL)isLocked;
/** 静音按钮事件 */
- (void)tma_controlView:(UIView *)controlView muteAction:(UIButton *)sender;
/** 倍速按钮事件 */
- (void)tma_controlViewRateAction;
/** 倍速设置 */
- (void)tma_controlViewSelectRate:(CGFloat)rate;
/** 截图按钮事件*/
- (void)tma_controlViewSnapshotAction;
/** 重播按钮事件 */
- (void)tma_repeatPlayAction;
/** 中间播放按钮事件 */
- (void)tma_controlView:(UIView *)controlView centerStartAction:(UIButton *)sender;
/** 加载失败按钮事件 */
- (void)tma_controlViewRetryAction;
/** 下载按钮事件 */
- (void)tma_controlView:(UIView *)controlView downloadVideoAction:(UIButton *)sender;
/** 切换分辨率按钮事件 */
- (void)tma_controlView:(UIView *)controlView resolutionAction:(UIButton *)sender;
/** slider的点击事件（点击slider控制进度） */
- (void)tma_controlView:(UIView *)controlView progressSliderTap:(CGFloat)value;
/** 开始触摸slider */
- (void)tma_controlView:(UIView *)controlView progressSliderTouchBegan:(CGFloat)value;
/** slider触摸中 */
- (void)tma_controlView:(UIView *)controlView progressSliderValueChanged:(CGFloat)value;
/** slider触摸结束 */
- (void)tma_controlView:(UIView *)controlView progressSliderTouchEnded:(CGFloat)value;
/** 控制层即将显示 */
- (void)tma_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
/** 控制层即将隐藏 */
- (void)tma_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
/** 双击手势播放or暂停 */
- (void)tma_controlViewDoubleTapAction;

@end
