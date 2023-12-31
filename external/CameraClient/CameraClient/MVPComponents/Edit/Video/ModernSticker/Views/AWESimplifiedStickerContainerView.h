//
//  AWESimplifiedSitckerContainerView.h
//  Pods
//
//  Created by jindulys on 2019/4/12.
//

#import <UIKit/UIKit.h>
#import "AWEVideoStickerEditCircleView.h"
#import "AWEEditorStickerGestureViewController.h"

@protocol AWESimplifiedStickerContainerViewDelegate <NSObject>
@optional
- (void)setSticker:(NSInteger)stickerEditId offsetX:(CGFloat)x offsetY:(CGFloat)y angle:(CGFloat)angle scale:(CGFloat)scale;

- (void)setSticker:(NSInteger)stickerEditId startTime:(CGFloat)startTime duration:(CGFloat)duration;

- (void)setSticker:(NSInteger)stickerEditId alpha:(CGFloat)alpha;

- (void)getSticker:(NSInteger)stickerEditId props:(IESInfoStickerProps *)props;

- (void)removeSticker:(NSInteger)stickerEditId;

- (BOOL)activeSticker:(NSInteger)stickerEditId;

- (void)selectTimeForStickerView:(AWEVideoStickerEditCircleView *)stickerView;

- (void)handleStickerStarted;//开始平移，pinch，rotate

- (void)handleStickerFinished;

- (void)cancelPinSticker:(NSInteger)stickerEditId;
@end

@class AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

@interface AWESimplifiedStickerContainerView : UIView<AWEEditorStickerGestureProtocol>

@property (nonatomic, strong) AWEVideoStickerEditCircleView *currentStickerView;
@property (nonatomic, strong, readonly) NSMutableArray<AWEVideoStickerEditCircleView *> *stickerViews;
@property (nonatomic, weak) id<AWESimplifiedStickerContainerViewDelegate> delegate;
@property (nonatomic, strong) NSValue *playerFrame;
/// Pin Sticker 这个功能有用到，此时才有值
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
/// 在此容器中被取消Pin的stickerId
@property (nonatomic, strong, readonly) NSMutableArray<NSNumber *> *cancelPinStickerIdArray;

@property (nonatomic, copy) void (^startPanGestureBlock)(void);
@property (nonatomic, copy) void (^finishPanGestureBlock)(void);

@property (nonatomic, weak) AWEEditorStickerGestureViewController *gestureManager;

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel playerOriginalRect:(CGRect)playerRect;
- (void)generateParamsWithFrame:(CGRect)frame;
// 恢复贴纸框
- (void)recoverStickerWithStickerInfos:(IESInfoStickerProps *)infos editSize:(CGSize)size setCurrentSticker:(BOOL)setCurrentSticker;

- (void)makeAllStickersResignActive;
- (void)restoreLastTimeSelectStickerView;
- (void)updateViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime;

#pragma mark - Pin
- (AWEVideoStickerEditCircleView *)touchPinnedStickerInVideoAndCancelPin:(NSValue *)touchPointValue;
/// 是否有任何一个信息化贴纸被Pin住
- (BOOL)hasAnyPinnedInfoSticker;
@end
