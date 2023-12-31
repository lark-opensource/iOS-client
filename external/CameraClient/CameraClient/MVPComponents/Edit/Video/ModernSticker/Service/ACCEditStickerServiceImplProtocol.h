//
//  ACCEditStickerServiceImplProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/16.
//

#import <Foundation/Foundation.h>

@class ACCStickerContainerView, ACCGroupedPredicate;

@protocol ACCEditStickerServiceImplProtocol <NSObject>

@property (nonatomic, weak, nullable) ACCStickerContainerView *stickerContainer;
@property (nonatomic, strong, nullable, readonly) ACCGroupedPredicate *needResetPreviewEdge;
@property (nonatomic, strong, nullable, readonly) ACCGroupedPredicate *needRecoverStickers;

- (void)recoverySticker;

- (void)syncRecordSticker;

- (void)expressStickers;

- (void)expressStickersOnCompletion:(nullable void (^)(void))completionHandler;

// 自渲染贴纸（例如 POI）在点击下一步的时候会将贴纸渲染到播放器内部，从发布页返回的时候会调用
// 此方法来移除播放器内部的贴纸特效，否则将会出现两个同样的贴纸（一个是自渲染视图，一个是播放器内部特效）
- (void)resetStickerInPlayer;

- (void)setStickersForPublish;

// 移除所有信息化贴纸
- (void)removeAllInfoStickers;

// 取消 pin
- (void)cancelAllPinSticker;

// finish edit
- (void)finish;

// 添加交互贴纸
- (void)addInteractionStickerInfoToArray:(nullable NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex;

- (void)startQuickTextInput;

- (void)updateStickersDuration:(NSTimeInterval)duration;

@end
