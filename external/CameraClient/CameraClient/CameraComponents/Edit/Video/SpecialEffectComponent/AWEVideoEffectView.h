//
//  AWEVideoEffectView.h
//  Aweme
//
//  Created by hanxu on 2017/4/10.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTVideoEditor/HTSVideoEditor.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

#if __has_include(<YYImage/YYImage.h>)
#import <YYImage/YYImage.h>
#elif __has_include(<YYWebImage/YYImage.h>)
#import <YYWebImage/YYImage.h>
#else
#import <YYImage/YYImage.h>
#endif

NS_ASSUME_NONNULL_BEGIN

//滤镜特效,按钮长按变大
//时间特效,选中变打钩
typedef enum : NSUInteger
{
    AWEVideoEffectViewTypeFilter,//滤镜特效
    AWEVideoEffectViewTypeTransition, //转场特效
    AWEVideoEffectViewTypeTool, // 道具特效
    AWEVideoEffectViewTypeTime,//时间特效
} AWEVideoEffectViewType;

@class AWEVideoEffectView,HTSVideoSepcialEffect,AWEVideoFilterEffect;
@protocol AWEVideoEffectViewDelegate <NSObject>
@optional
//长按事件代理,对应于滤镜特效
- (void)videoEffectView:(AWEVideoEffectView *)effectView didFinishLongPressWithType:(IESEffectModel *)effect;
- (void)videoEffectView:(AWEVideoEffectView *)effectView didCancelLongPressWithType:(IESEffectModel *)effect;
- (void)videoEffectView:(AWEVideoEffectView *)effectView beginLongPressWithType:(IESEffectModel *)effect;
- (void)videoEffectView:(AWEVideoEffectView *)effectView beingLongPressWithType:(IESEffectModel *)effect;
// 点击事件
- (void)videoEffectView:(AWEVideoEffectView *)effectView didSelectEffect:(IESEffectModel *)effect;
//点击事件,对应于时间特效, return true means cell could show clicked style
- (void)videoEffectView:(AWEVideoEffectView *)effectView clickedCellWithTimeEffect:(HTSVideoSepcialEffect *)effect showClickedStyle:(BOOL)showClickedStyle;
- (BOOL)videoEffectViewShouldShowClickedStyleWithTimeEffect:(HTSVideoSepcialEffect *)effect;
//点击事件,对应于转场特效
- (void)videoEffectView:(AWEVideoEffectView *)effectView clickedCellWithTransitionEffect:(IESEffectModel *)effect;
//点击事件，对应于道具特效
- (void)videoEffectView:(AWEVideoEffectView *)effectView didSelectToolEffect:(IESEffectModel *)effect;
- (void)videoEffectView:(AWEVideoEffectView *)effectView didDeselectToolEffect:(IESEffectModel *)effect;
//点击撤销按钮
- (void)videoEffectView:(AWEVideoEffectView *)effectView didClickedRevokeBtn:(UIButton *)btn;
@end


//自定义cell
@interface AWEVideoEffectViewCollectionCell : UICollectionViewCell
@property (nonatomic, strong) YYAnimatedImageView *imageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *colorView;
@property (nonatomic, strong) UIColor *coverColor;
@property (nonatomic, assign) AWEEffectDownloadStatus downloadStatus;
- (void)updateText:(NSString *)text;
- (void)setCenterImage:(nullable UIImage *)img size:(CGSize)size;
@end

//滤镜特效cell,需要按住使用
@interface  AWEVideoEffectViewFilterCell: AWEVideoEffectViewCollectionCell
@property (nonatomic, copy) void (^longPressBlock)(AWEVideoEffectViewCollectionCell *, UIGestureRecognizerState);
@end
//时间特效cell,需要点击使用
@interface  AWEVideoEffectViewTimeCell: AWEVideoEffectViewCollectionCell

@end
//转场特效cell,需要点击使用
@interface AWEVideoEffectViewTransitionCell: AWEVideoEffectViewCollectionCell

@end

//道具特效 cell，需要点击使用
@interface AWEVideoEffectViewToolCell : AWEVideoEffectViewCollectionCell

@end


//底部特效view
@interface AWEVideoEffectView : UIView
@property (nonatomic, assign, readonly) AWEVideoEffectViewType type;
@property (nonatomic, weak) id<AWEVideoEffectViewDelegate> delegate;

@property (nonatomic, copy, readonly) NSString *effectCategory; //特效所属分类
@property (nonatomic, strong, readonly) IESEffectModel *selectedToolEffect; //选中的道具特效
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel; ///<  for time machine effect usage.

@property (nonatomic, assign) BOOL hideEffectCategoryMessage;

//初始化时间特效还是滤镜特效
//如果是时间特效，effects 和 effectCategory 参数为 nil 即可
- (instancetype)initWithType:(AWEVideoEffectViewType)type
                     effects:(nullable NSArray<IESEffectModel *> *)effects
              effectCategory:(nullable NSString *)effectCategory
                publishModel:(AWEVideoPublishViewModel *)publishModel;

//下载成功更新特效列表
- (void)updateWithType:(AWEVideoEffectViewType)type
               effects:(nullable NSArray<IESEffectModel *> *)effects
        effectCategory:(nullable NSString *)effectCategory;
//更新特定的特效cell
- (void)updateCellWithEffect:(nullable IESEffectModel *)effect;
- (void)reload;
//时间特效 operation
- (void)updateCellWithTimeEffect:(HTSPlayerTimeMachineType)type;
- (void)selectTimeEffect:(HTSPlayerTimeMachineType)type;
- (void)setDescriptionText:(NSString *)text;

//在滤镜特效中,需要隐藏撤销
- (void)hideRevokeBtn:(BOOL)hide;

// 道具特效或者时间特效中，改变区间后，提示文案变成：已选择：xs
- (void)setUpScalableRangeViewTip:(CGFloat)selectedDuration;
- (void)resetToolEffectTip;

// 道具特效选中或取消选中指定的特效
- (void)selectToolEffectWithEffectId:(nullable NSString *)effectId animated:(BOOL)animated;
- (void)deselectToolEffectWithEffectId:(nullable NSString *)effectId;
- (BOOL)hasValidMultiVoiceEffectSegment;

// 适配优化二期样式：https://bytedance.feishu.cn/docs/doccnOoRhkgxlh7TqMeiQp5flQe
- (NSString *)effectCategoryTitle;
- (void)didClickedRevokeBtn:(UIButton *)btn;

@end

NS_ASSUME_NONNULL_END
