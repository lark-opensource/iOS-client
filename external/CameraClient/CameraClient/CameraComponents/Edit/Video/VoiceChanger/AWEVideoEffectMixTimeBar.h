//
//  AWEVideoEffectMixTimeBar.h
//  Aweme
//
//  Created by Liu Bing on 4/10/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTVideoEditor/IESMMEffectTimeRange.h>
#import "AWEVideoPlayControl.h"
#import "AWEVideoEffectRangeView.h"

@protocol AWEVideoEffectMixTimeBarDelegate <NSObject>
@optional
- (NSString *)effectCategoryWithEffectId:(NSString *)effectId;
- (UIColor *)effectColorWithEffectId:(NSString *)effectId;
- (NSString *)effectIdWithEffectType:(IESEffectFilterType)type;
- (void)userWillMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress;
- (void)userDidMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress;
- (void)userDidFinishMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress;

// 用户修改AWEVideoEffectScalableRangeView区间的回调 respectively are toolEffectRangeView and timeEffectRangeView
- (CGFloat)userCouldChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo proportion:(CGFloat)proportion changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType inTimeEffectView:(BOOL)inTimeEffectView;
- (void)userWillChangeRangeViewEffectRangeInTimeEffectView:(BOOL)inTimeEffectView;
- (void)userDidChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo proportion:(CGFloat)proportion changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType  inTimeEffectView:(BOOL)inTimeEffectView;
- (void)userDidFinishChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType inTimeEffectView:(BOOL)inTimeEffectView;

@end

@interface AWEVideoEffectMixTimeBar : UIView

@property (nonatomic, strong) AWEVideoPlayControl *playProgressControl;//播放进度条
@property (nonatomic, strong) AWETimeSelectControl *timeSelectControl;//时间特效中要显示的大控制块
@property (nonatomic, strong) UIView *timeReverseMask;//时间特效中的"时光倒流"需要全进度条遮罩

@property (nonatomic, strong) IESMMEffectTimeRange *currentEffectTimeRange;//记录当前选择了哪个滤镜特效
@property (nonatomic, assign) BOOL needReverseTime;//是否需要翻转时间

@property (nonatomic, weak) id<AWEVideoEffectMixTimeBarDelegate> delegate;

//获取播放控件的进度
- (CGFloat)getPlayControlViewProgress;

- (void)animateElements;
// 更新道具特效是否展示toolbar标记的方法
- (void)updateShowingToolEffectRangeViewIfNeededWithCategoryKey:(NSString *)categoryKey effectSelected:(BOOL)selected;
- (void)updatePlayProgressWithTime:(CGFloat)time totalDuration:(CGFloat)totalDuration;//更新播放进度条
- (void)updateSelectTime:(CGFloat)time totalDuration:(CGFloat)totalDuration;//

- (void)refreshBarWithImageArray:(NSArray<UIImage *> *)imageArray;//用抽帧得到的图片数组设置bar的背景

- (void)refreshBarWithEffectArray:(NSArray<IESMMEffectTimeRange*> *)effectArray
                    totalDuration:(CGFloat)totalDuration;//

// 设置视频进度条的tintColor，如果是道具特效tab就显示白色，其它显示默认（黄色）
- (void)setUpPlayProgressControlTintColor:(BOOL)isToolEffect;

//method relative to "time" tab
- (void)refreshTimeEffectRangeViewWithRange:(IESMMEffectTimeRange *)timeEffectRange totalDuration:(CGFloat)totalDuration;
- (void)updateShowingTimeEffectRangeViewIfNeededWithType:(HTSPlayerTimeMachineType)type;
- (void)setUpTimeEffectRangeViewAlpha:(CGFloat)alpha;

+ (CGFloat)timeBarHeight;

@end
