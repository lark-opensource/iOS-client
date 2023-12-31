//
//  ACCStickerPanelServiceProtocol.h
//  CameraClient
//
//  Created by HuangHongsen on 2021/1/7.
//

#ifndef ACCStickerPanelServiceProtocol_h
#define ACCStickerPanelServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCStickerSelectionContext.h"

typedef NS_ENUM(NSUInteger, ACCStickerPannelObserverPriority) {
    ACCStickerPannelObserverPriorityNone = 0,
    ACCStickerPannelObserverPriorityVote = 1,
    ACCStickerPannelObserverPriorityLive = 2,
    ACCStickerPannelObserverPriorityPOI = 3,
    ACCStickerPannelObserverPriorityCustom = 4,
    ACCStickerPannelObserverPrioritySearch = 5,
    ACCStickerPannelObserverPriorityLyrics = 6,
    ACCStickerPannelObserverPriorityInfo = 7
};

@class IESEffectModel, IESThirdPartyStickerModel, IESInfoStickerProps;

@protocol ACCStickerPannelObserver <NSObject>

/// 添加贴纸
/// @param sticker 贴纸信息
/// @param tabName 点击的 tab
/// @param willSelectHandle 确定需要添加贴纸的回调，例如贴纸达到上限不会真正添加贴纸
/// @param dismissPanelHandle 添加结束，需要收起面板的回调
- (BOOL)handleSelectSticker:(IESEffectModel *)sticker
                    fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void(^)(ACCStickerType type, BOOL animated))dismissPanelHandle;

- (ACCStickerPannelObserverPriority)stikerPriority;

@optional

- (BOOL)handleThirdPartySelectSticker:(IESThirdPartyStickerModel *)sticker
                     willSelectHandle:(dispatch_block_t)willSelectHandle
                   dismissPanelHandle:(void(^)(BOOL animated))dismissPanelHandle;

@end

@protocol ACCStickerPanelServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *willShowStickerPanelSignal;
@property (nonatomic, strong, readonly) RACSignal *willDismissStickerPanelSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCStickerSelectionContext *> *didDismissStickerPanelSignal;

@property (nonatomic, copy) void(^configureGestureWithView)(UIView *view);

@property (nonatomic, assign, readonly) BOOL stickerPanelShowing;

- (void)registObserver:(id<ACCStickerPannelObserver>)observer;

@end

#endif /* ACCStickerPanelServiceProtocol_h */
