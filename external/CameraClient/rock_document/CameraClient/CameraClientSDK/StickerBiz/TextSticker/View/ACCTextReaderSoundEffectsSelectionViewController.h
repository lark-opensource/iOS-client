//
//  ACCTextReaderSoundEffectsSelectionViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/2.
//

#import <UIKit/UIKit.h>

#import <CreativeKitSticker/ACCStickerContainerView.h>

#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCStickerDataProvider.h"
#import "ACCStickerPlayerApplying.h"
#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCTextReaderSoundEffectsSelectionViewControllerProviderProtocol <NSObject>

- (void)didSelectTTSAudio:(NSString *)audioFilePath
                speakerID:(NSString *)speakerID;

- (void)didTapFinishDelegate:(NSString *)audioFilePath
                   speakerID:(NSString *)speakerID
                 speakerName:(NSString *)speakerName;

- (void)didTapCancelDelegate;

- (AWETextStickerReadModel *)getTextReaderModel;

@end

@interface ACCTextReaderSoundEffectsSelectionViewController : UIViewController

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
               stickerContainerView:(ACCStickerContainerView *)stickerContainerView
                             player:(id<ACCStickerPlayerApplying>) player
                  transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService
                       dataProvider:(id<ACCTextReaderSoundEffectsSelectionViewControllerProviderProtocol>)dataProvider;

@end

NS_ASSUME_NONNULL_END
