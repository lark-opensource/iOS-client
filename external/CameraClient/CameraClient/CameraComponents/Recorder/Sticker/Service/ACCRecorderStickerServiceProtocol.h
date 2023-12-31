//
//  ACCRecorderStickerServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/17.
//

#ifndef ACCRecorderStickerServiceProtocol_h
#define ACCRecorderStickerServiceProtocol_h

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#import "ACCStickerCompoundHandler.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecorderStickerServiceProtocol <NSObject>

@property (nonatomic, weak, readonly) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, strong, readonly) ACCStickerHandler<ACCStickerCompoundHandler> *compoundHandler;
@property (nonatomic, assign) BOOL containerInteracting; // 判断是否需要隐藏拍摄按钮：YES=需要；NO=不需要

- (void)registerStickerHandler:(ACCStickerHandler *)handler;

/// 拍摄页即将进入编辑页时更新recorderInteractionStickers，以便于编辑页同步数据
/// @param recorderInteractionStickers 
/// @param stickerIndex
- (void)addRecorderInteractionStickerInfoToArray:(NSMutableArray *)recorderInteractionStickers idx:(NSInteger)stickerIndex;

- (void)toggleForbitHidingStickerContainerView:(BOOL)shouldForbid;
- (void)toggleStickerContainerViewHidden:(BOOL)shouldHide;

- (void)recoverStickers;
- (void)updateStickerContainer;

@end

NS_ASSUME_NONNULL_END

#endif
