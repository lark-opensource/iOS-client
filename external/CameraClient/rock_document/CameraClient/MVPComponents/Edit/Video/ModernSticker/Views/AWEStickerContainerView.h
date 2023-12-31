//
//  AWEStickerContainerView.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//  信息化贴纸的容器

#import <UIKit/UIKit.h>
#import "AWEVideoStickerEditCircleView.h"
#import "AWEStoryDeleteView.h"
#import "AWEStickerBaseContainerView.h"

@class AWEEditorStickerGestureViewController;

@protocol AWEEditorStickerGestureProtocol, ACCMusicModelProtocol;

@protocol AWEStickerContainerViewDelegate <NSObject>

- (CGRect)getstickerEditBoundBox:(NSInteger)stickerEditId;

@optional
- (void)setSticker:(NSInteger)stickerEditId offsetX:(CGFloat)x offsetY:(CGFloat)y angle:(CGFloat)angle scale:(CGFloat)scale;

- (void)setSticker:(NSInteger)stickerEditId startTime:(CGFloat)startTime duration:(CGFloat)duration;

- (void)setSticker:(NSInteger)stickerEditId alpha:(CGFloat)alpha;

- (void)setSticker:(NSInteger)stickerEditId scale:(CGFloat)scale;

- (void)getSticker:(NSInteger)stickerEditId props:(IESInfoStickerProps *)props;

- (void)removeSticker:(NSInteger)stickerEditId;

- (BOOL)activeSticker:(NSInteger)stickerEditId;

- (void)selectTimeForStickerView:(AWEVideoStickerEditCircleView *)stickerView;

- (void)handleStickerStarted:(NSInteger)stickerId;//开始平移，pinch，rotate

- (void)handleStickerFinished:(NSInteger)stickerId;

- (CGSize)getInfoStickerSize:(NSInteger)stickerEditId;

- (void)pinSticker:(AWEVideoStickerEditCircleView *)stickerView;

- (void)cancelPinSticker:(NSInteger)stickerEditId;
@end

@class AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

typedef NSDictionary*(^AWEStickerContainerViewStickerSizeBlock)(NSInteger stickerId);
@interface AWEStickerContainerView : AWEStickerBaseContainerView <AWEEditorStickerGestureProtocol>

@property (nonatomic, strong) AWEVideoStickerEditCircleView *currentStickerView;
@property (nonatomic, strong, readonly) NSMutableArray<AWEVideoStickerEditCircleView *> *stickerViews;
@property (nonatomic, weak) id<AWEStickerContainerViewDelegate> delegate;
@property (nonatomic, weak) AWEStoryDeleteView *deleteView;
@property (nonatomic, strong) NSValue *playerFrame;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService; /// Pin贴纸功能所需


@property (nonatomic, copy) void (^startPanGestureBlock)(void);
@property (nonatomic, copy) void (^finishPanGestureBlock)(void);
@property (nonatomic, copy) AWEStickerContainerViewStickerSizeBlock stickerSizeBlock;

@property (nonatomic, weak) AWEEditorStickerGestureViewController *gestureManager;

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel;

// 添加贴纸框
- (AWEVideoStickerEditCircleView *)addStickerWithStickerInfos:(IESInfoStickerProps *)infos isLyricSticker:(BOOL)isLyricSticker editSize:(CGSize)size center:(CGPoint)center;
// 恢复贴纸框
- (void)recoverStickerWithStickerInfos:(IESInfoStickerProps *)infos isLyricSticker:(BOOL)isLyricSticker editSize:(CGSize)size center:(CGPoint)center;
// 更新贴纸框
- (void)updateStickerWithStickerInfos:(IESInfoStickerProps *)infos editSize:(CGSize)size center:(CGPoint)center;

// 贴纸 id 更新
- (void)handleStickerIdChangedFrom:(NSInteger)oldStikcerId newStickerId:(NSInteger)newStickerId;

- (void)removeStickerWithStickerId:(NSInteger)stickerId;

- (void)updateStickerCircleViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime editService:(id<ACCEditServiceProtocol>)editService;

// 更新歌词贴纸大小和位置，在手势触发前更新，存在 Bug
- (void)updateLyricStickerInfoPositionAndSize;

- (void)makeAllStickersResignActive;

// 显示歌词贴纸提示“点击更换样式”
- (void)checkLyricStickerViewHintShow;

- (void)fixViewAndStickerDiff:(AWEVideoStickerEditCircleView *)stickerView;

- (void)fixStickerAndViewScaleDiffWithStickerView:(AWEVideoStickerEditCircleView *)stickerView;

- (BOOL)hasEditingSticker;
- (NSInteger)stickersCount;

// 返回贴纸editId集合
- (NSArray *)stickerEditIds;

// 取消选中贴纸
- (void)deselectCurrentSticker;
- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model;
- (void)removeAllStickerViews;

- (void)makeStickerCurrent:(AWEVideoStickerEditCircleView *)stickerView showHandleBar:(BOOL)show;

- (void)dismissHintTextWithAnimation:(BOOL)animated;

#pragma mark - Pin
- (AWEVideoStickerEditCircleView *)touchPinnedStickerInVideoAndCancelPin:(NSValue *)touchPointValue;

- (AWEVideoStickerEditCircleView *)cancelPinnedStickerWithStickerId:(NSInteger )stickerId;

@end
