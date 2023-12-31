//
//  ACCEditServiceProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VEEditorSession+Effect.h>

#import "ACCEditBeautyProtocol.h"
#import "ACCEditFilterProtocol.h"
#import "ACCEditStickerProtocol.h"
#import "ACCEditPreviewProtocol.h"
#import "ACCEditHDRProtocol.h"
#import "ACCEditAudioEffectProtocol.h"
#import "ACCEditEffectProtocol.h"
#import "ACCEditCaptureFrameProtocol.h"
#import "ACCMediaContainerViewProtocol.h"
#import "ACCEditSessionBuilderProtocol.h"
#import "ACCCameraSubscription.h"
#import "ACCEditSessionLifeCircleEvent.h"
#import "ACCEditImageAlbumMixedProtocol.h"
#import "ACCImageEditHDRProtocol.h"
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>
#import "ACCEditMultiTrackProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol <ACCCameraSubscription>

@property (nonatomic, strong, readonly) id<ACCEditBeautyProtocol> beauty;
@property (nonatomic, strong, readonly) id<ACCEditFilterProtocol> filter;
@property (nonatomic, strong, readonly) id<ACCEditStickerProtocol> sticker;
@property (nonatomic, strong, readonly) id<ACCEditCanvasProtocol> canvas;
@property (nonatomic, strong, readonly) id<ACCEditPreviewProtocol> preview;
@property (nonatomic, strong, readonly) id<ACCEditHDRProtocol> hdr;
@property (nonatomic, strong, readonly) id<ACCEditAudioEffectProtocol> audioEffect;
@property (nonatomic, strong, readonly) id<ACCEditEffectProtocol> effect;
@property (nonatomic, strong, readonly) id<ACCEditCaptureFrameProtocol> captureFrame;
@property (nonatomic, strong, readonly) id<ACCEditImageAlbumMixedProtocol> imageAlbumMixed;
@property (nonatomic, strong, readonly) id<ACCImageEditHDRProtocol> imageEditHDR;
@property (nonatomic, strong, readonly) id<ACCEditMultiTrackProtocol> multiTrack;

@property (nonatomic, strong) id<ACCEditSessionBuilderProtocol> editBuilder;
@property (nonatomic, strong, readonly) UIView <ACCMediaContainerViewProtocol> *mediaContainerView;

- (void)buildEditSession;
// Player black edge treatment
- (void)resetPlayerAndPreviewEdge;

@optional

@property (nonatomic, copy) dispatch_block_t firstFrameTrackBlock;

// TODO: NLE yuanming & xiaobing
- (void)resetEditSessionWithPublishModel:(AWEVideoPublishViewModel *)publishModel;
- (void)resetPreModel;

@end

NS_ASSUME_NONNULL_END
