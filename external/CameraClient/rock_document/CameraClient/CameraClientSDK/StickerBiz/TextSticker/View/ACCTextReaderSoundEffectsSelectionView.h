//
//  ACCTextReaderSoundEffectsSelectionView.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/8.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextReaderSoundEffectsSelectionView : UIView

@property (nonatomic, copy) void (^didSelectSoundEffectCallback)(NSString * _Nullable audioFilePath, NSString * _Nullable audioSpeakerID);
@property (nonatomic, copy) void (^didTapFinishCallback)(NSString *audioFilePath, NSString *speakerID, NSString *speakerName);
@property (nonatomic, copy) AWETextStickerReadModel * (^getTextReaderModelBlock)(void);

@end

NS_ASSUME_NONNULL_END
