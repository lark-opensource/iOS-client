//
//  ACCRecordTrackService.h
//  Pods
//
//  Created by guochenxiang on 2020/7/6.
//

#import <Foundation/Foundation.h>
#import "AWEVideoPublishViewModel.h"
#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

NS_ASSUME_NONNULL_BEGIN

@class IESMMCamera, IESEffectModel;
@protocol IESMMRecoderProtocol;

///
@protocol ACCRecordVideoEventHandler <NSObject>

@optional
- (NSDictionary *)recordVideoEvent;

@end

///
@protocol ACCRecordTrackService <NSObject>

@required

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)configTrackDidLoad;
- (void)trackPauseRecordWithCameraService:(id<ACCCameraService>)cameraService error:(NSError *)error sticker:(IESEffectModel *)sticker beautyStatus:(NSInteger)beautyStatus;
- (void)trackEnterVideoShootPageWithSwapCamera:(BOOL)isSwapCamera;
- (void)trackPreviewPerformanceWithInfo:(NSDictionary *)info nextAction:(NSString *)nextAction;
- (void)trackError:(NSError *)error action:(NSString *)action info:(NSDictionary *)info;

- (void)trackRecordVideoEventWithSticker:(IESEffectModel *)sticker localSticker:(IESEffectModel *)localSticker prioritizedStickers:(NSArray<IESEffectModel *> *)prioritizedStickers;
- (void)trackRecordVideoEventWithCameraService:(id<ACCCameraService>)cameraService;
- (void)registRecordVideoHandler:(id<ACCRecordVideoEventHandler>)handler;

@property (nonatomic, copy) NSString *recordModeTrackName;

@end

NS_ASSUME_NONNULL_END
