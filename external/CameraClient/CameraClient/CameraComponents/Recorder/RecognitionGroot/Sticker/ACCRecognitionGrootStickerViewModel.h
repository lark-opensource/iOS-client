//
//  ACCRecognitionGrootStickerViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/27.
//

#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCRecognitionGrootStickerView.h"
#import "ACCRecognitionGrootStickerViewFactory.h"
#import "ACCGrootStickerModel.h"
#import "ACCRecognitionGrootStickerHandler.h"

@class ACCRecognitionGrootStickerHandler;

@interface ACCRecognitionGrootStickerViewModel : ACCRecorderViewModel<ACCRecognitionGrootStickerViewDelegate>

@property (nonatomic, strong, nonnull) RACSignal *clickViewSignal;
@property (nonatomic, weak  , nullable) ACCRecognitionGrootStickerHandler *grootStickerHandler;

- (void)trackGrootStickerPropShow:(nonnull NSString *)enterFrom;
- (void)trackGrootStickerPropDelete:(nonnull NSString *)enterFrom;
- (void)trackGrootStickerClickChangeSpecies:(nonnull NSString *)enterFrom;
- (void)trackGrootStickerSlideSpeciesCard:(nonnull NSString *)enterFrom;
- (void)trackGrootStickerConfirmSpeciesCard:(nonnull NSString *)enterFrom;

@end

