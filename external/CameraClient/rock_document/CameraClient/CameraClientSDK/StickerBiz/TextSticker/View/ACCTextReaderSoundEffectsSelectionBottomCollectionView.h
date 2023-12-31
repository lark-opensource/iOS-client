//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionView.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/18.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionView : UICollectionView

@property (nonatomic, copy, nullable, readonly) NSString *selectedAudioFilePath;
@property (nonatomic, copy, nullable, readonly) NSString *selectedAudioSpeakerID;
@property (nonatomic, copy, nullable, readonly) NSString *selectedAudioSpeakerName;
@property (nonatomic, copy) void (^didSelectSoundEffectCallback)(NSString * _Nullable audioFilePath, NSString * _Nullable audioSpeakerID);
@property (nonatomic, copy, nullable) AWETextStickerReadModel * (^getTextReaderModelBlock)(void);
@property (nonatomic, copy) void (^showLoadingView)(void);
@property (nonatomic, copy) void (^hideLoadingView)(void);
@property (nonatomic, assign, getter=isUsingOwnAudioPlayer) BOOL usingOwnAudioPlayer;

- (void)prepareForClosing;

@end

NS_ASSUME_NONNULL_END
