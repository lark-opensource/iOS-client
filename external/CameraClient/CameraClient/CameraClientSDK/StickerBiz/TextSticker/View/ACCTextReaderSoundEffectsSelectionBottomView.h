//
//  ACCTextReaderSoundEffectsSelectionBottomView.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/9.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const kACCTextReaderSoundEffectsSelectionBottomViewHeight;
extern CGFloat const kACCTextReaderSoundEffectsSelectionBottomViewWithBottomBarHeight;

typedef NS_ENUM(NSUInteger, ACCTextReaderSoundEffectsSelectionBottomViewType) {
    ACCTextReaderSoundEffectsSelectionBottomViewTypeNormal = 0,
    ACCTextReaderSoundEffectsSelectionBottomViewTypeBottomBar
};

@interface ACCTextReaderSoundEffectsSelectionBottomView : UIView

@property (nonatomic, strong, readonly) UIView *cancelSaveBtnBarView;

@property (nonatomic, copy) void (^didSelectSoundEffectCallback)(NSString * _Nullable audioFilePath, NSString * _Nullable audioSpeakerID);
@property (nonatomic, copy) void (^didTapCancelCallback)(void);
@property (nonatomic, copy) void (^didTapFinishCallback)(NSString *audioFilePath, NSString *speakerID, NSString *speakerName);
@property (nonatomic, copy) AWETextStickerReadModel * (^getTextReaderModelBlock)(void);

- (instancetype)initWithFrame:(CGRect)frame
                         type:(ACCTextReaderSoundEffectsSelectionBottomViewType)type
        isUsingOwnAudioPlayer:(BOOL)isUsingOwnAudioPlayer;
- (void)setupUI;
- (void)didTapFinishButton:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
