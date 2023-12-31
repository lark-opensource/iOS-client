//
//  AWEStickerApplyHandlerContainer.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/5/8.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>

// Services
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecordPropService.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordConfigService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import "AWEStickerViewLayoutManagerProtocol.h"
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCRecordModeFactory.h"

//viewModel
#import "ACCPropViewModel.h"

// UI
#import <CameraClient/ACCKaraokeService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerApplyHandlerContainer;
@protocol IESServiceProvider;

@protocol AWEStickerApplyHandlerProtocol <NSObject>

@required

@property (nonatomic, weak) AWEStickerApplyHandlerContainer *container;

@optional

- (void)handlerDidBecomeActive;

- (void)componentDidAppear;

/**
 * 即将应用道具到camera上
 * Called before apply the sticker to the camera.
 * @param cameraService the camera object.
 * @param sticker the sticker will apply to camera.
 */
- (void)camera:(id<ACCCameraService>)cameraService willApplySticker:(IESEffectModel * _Nullable)sticker;

/**
 * 已经成功应用道具到camera上
 * Called after apply the sticker to the camera successfully.
 * @param cameraService the camera object.
 * @param sticker the sticker did apply to camera.
 */
- (void)camera:(id<ACCCameraService>)cameraService didApplySticker:(IESEffectModel * _Nullable)sticker success:(BOOL)success;

/**
 * 处理camera的messageHandler发出的消息
 */
- (void)camera:(id<ACCCameraService>)cameraService didRecvMessage:(IESMMEffectMessage * _Nonnull)message;

/**
 * 处理camera的IESCameraActionBlock发出的消息
 */
- (void)camera:(id<ACCCameraService>)cameraService didTakeAction:(IESCameraAction)action error:(NSError * _Nullable)error data:(id _Nullable)data;

- (void)didChangeLayoutManager:(id <AWEStickerViewLayoutManagerProtocol>)layoutManager;

@end

@interface AWEStickerApplyBaseHandler : NSObject <AWEStickerApplyHandlerProtocol>
@property (nonatomic, weak) AWEStickerApplyHandlerContainer *container;
@end

@interface AWEStickerApplyHandlerContainer : NSObject

/// 道具业务子视图管理
@property (nonatomic, strong, nullable) id<AWEStickerViewLayoutManagerProtocol> layoutManager;
@property (nonatomic, assign) BOOL isExposePanelEnabled;

/// Services
@property (nonatomic, strong, readonly) id<ACCCameraService> cameraService;
@property (nonatomic, strong, readonly) id<ACCRecordPropService> propService;
@property (nonatomic, strong, readonly) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong, readonly) id<ACCRecordConfigService> configService;
@property (nonatomic, strong, readonly) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong, readonly) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong, readonly) id<ACCFilterService> filterService;
@property (nonatomic, weak, readonly) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong, readonly) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong, readonly) id<ACCRecordModeFactory> modeFactory;

//TODO: @zhangchengtao 道具全量以后删除
@property (nonatomic, strong, readonly) ACCPropViewModel *propViewModel;


/// UI
@property (nonatomic, weak, readonly) UIViewController *containerViewController;
@property (nonatomic, weak, readonly) id<ACCRecorderViewContainer> viewContainer;

- (instancetype)initWithCameraService:(id<ACCCameraService>)cameraService
                          propService:(id<ACCRecordPropService>)propService
                          flowService:(id<ACCRecordFlowService>)flowService
                        configService:(id<ACCRecordConfigService>)configService
                    switchModeService:(id<ACCRecordSwitchModeService>)switchModeService
                         trackService:(id<ACCRecordTrackService>)trackService
                        filterService:(id<ACCFilterService>)filterService
                      serviceProvider:(id<IESServiceProvider>)serviceProvider
                        propViewModel:(ACCPropViewModel *)propViewModel
              containerViewController:(UIViewController *)containerViewController
                        viewContainer:(id<ACCRecorderViewContainer>)viewContainer
                          modeFactory:(id<ACCRecordModeFactory>)modeFactory;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)addHandler:(id<AWEStickerApplyHandlerProtocol>)handler;

- (void)componentDidAppear;

/**
 * 即将应用道具到camera上
 * Called before apply the sticker to the camera.
 * @param cameraService the camera object.
 * @param sticker the sticker will apply to camera.
 */
- (void)camera:(id<ACCCameraService>)cameraService willApplySticker:(IESEffectModel * _Nullable)sticker;

/**
 * 已经应用道具到camera上
 * Called after apply the sticker to the camera successfully.
 * @param cameraService the camera object.
 * @param sticker the sticker did apply to camera.
 * @param success apply sticker to camera result.
 */
- (void)camera:(id<ACCCameraService>)cameraService didApplySticker:(IESEffectModel * _Nullable)sticker success:(BOOL)success;

/**
 * 处理camera的messageHandler发出的消息
 */
- (void)camera:(id<ACCCameraService>)cameraService
didRecvMessage:(IESMMEffectMessage * _Nonnull)message;

/**
 * 处理camera的action变化通知
 */
- (void)camera:(id<ACCCameraService>)cameraService
 didTakeAction:(IESCameraAction)action
         error:(NSError * _Nullable)error
          data:(id _Nullable)data;

@end

NS_ASSUME_NONNULL_END
