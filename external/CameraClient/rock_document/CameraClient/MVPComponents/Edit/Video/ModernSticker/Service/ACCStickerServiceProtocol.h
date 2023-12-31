//
//  ACCStickerServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/9/4.
//

#ifndef ACCStickerServiceProtocol_h
#define ACCStickerServiceProtocol_h

#import "ACCStickerHandler.h"
#import "ACCStickerCompoundHandler.h"
#import "ACCStickerBizDefines.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCStickerSelectionContext.h"

NS_ASSUME_NONNULL_BEGIN

@class RACSignal<__covariant ValueType>;

@class ACCStickerContainerView;
@class ACCStickerCompoundHandler;
@protocol ACCSerializationProtocol;
@class ACCImageAlbumItemStickerInfo;

@protocol ACCStickerServiceSubscriber <NSObject>
@optional

// text input
- (void)onStartQuickTextInput;

@end

@protocol ACCStickerServiceProtocol <NSObject>

@property (nonatomic, weak, readonly) ACCStickerContainerView *stickerContainer;

@property (nonatomic, strong, readonly) ACCStickerHandler<ACCStickerCompoundHandler> *compoundHandler;
@property (nonatomic, strong, readonly) RACSignal *willStartEditingStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *didFinishEditingStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *stickerDeselectedSignal;

@property (nonatomic, assign, readonly ) BOOL isAllStickersInPlayer;
@property (nonatomic, assign, readonly ) BOOL isAllInfoStickersInPlayer;
@property (nonatomic, assign, readonly ) BOOL hasStickers;
@property (nonatomic, assign, readonly ) BOOL canAddMoreText;
@property (nonatomic, assign, readonly ) BOOL needAdaptPlayer;
@property (nonatomic, assign, readonly ) BOOL enableAllStickerCovertToImageAlbum;
@property (nonatomic, assign, readonly ) NSInteger infoStickerCount;
// 仅限需要受总个数限制的贴纸总数
@property (nonatomic, assign, readonly ) NSInteger stickerCount;
@property (nonatomic, assign, readonly ) BOOL needAdapterTo9V16FrameForPublish;

- (void)registStickerHandler:(ACCStickerHandler *)handler;

- (void)addSubscriber:(id<ACCStickerServiceSubscriber>)subscriber;

- (void)startEditingStickerOfType:(ACCStickerType)type;

- (void)finishEditingStickerOfType:(ACCStickerType)type ;

- (void)deselectAllSticker;

- (void)dismissPreviewEdge;

// the edit id will be change after VEEditorSession update video data,
// this method is used to synchronize stickerId between stickerContentView and HTSVideoData;
- (void)syncStickerInfoWithVideo;

// VE will regenerate sticker somettime, wee should refresh our sticker id in container to avoid less control of VE stickers
- (void)updateStickerViewWithOriginStickerId:(NSInteger)originStickerId
                                newStickerId:(NSInteger)newStickerId;
- (void)resetStickerInPlayer;

- (BOOL)isAllEditEffectInPlayerContaienr;

@optional

- (void)recoveryStickersForContainer:(ACCStickerContainerView *)containerView
                          imageModel:(ACCImageAlbumItemStickerInfo *)stickerModel;

- (void)updateStickersDuration:(NSTimeInterval)duration;

- (BOOL)isSelectedSticker:(UIGestureRecognizer *)gesture;

@property (nonatomic, strong, nullable) ACCStickerContainerView *simStickerContainer;
// 独立计数，不受贴纸总个数限制的贴纸个数
@property (nonatomic, assign, readonly ) NSInteger independentStickersCount;

@end


NS_ASSUME_NONNULL_END

#endif /* ACCStickerServiceProtocol_h */
