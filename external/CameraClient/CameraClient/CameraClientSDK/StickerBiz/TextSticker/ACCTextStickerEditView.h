//
//  ACCTextStickerEditView.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/15.
//

#import <CreationKitArch/AWEStudioExcludeSelfView.h>
#import "ACCTextStickerView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, ACCTextStickerEditAbilityOptions) {
    ACCTextStickerEditAbilityOptionsNone              = 0,
    ACCTextStickerEditAbilityOptionsSupportTextReader = 1 << 0,
    ACCTextStickerEditAbilityOptionsSupportSocial     = 1 << 1,
    ACCTextStickerEditAbilityOptionsNotSupportMention     = 1 << 2
};

typedef NS_OPTIONS(NSUInteger, ACCTextStickerEditEnterInputMode) {
    ACCTextStickerEditEnterInputModeKeyword = 0,
    ACCTextStickerEditEnterInputModeTextLib = 1
};

@class AWEVideoPublishViewModel;

@interface ACCTextStickerEditView : AWEStudioExcludeSelfView

@property (nonatomic, strong, readonly) __kindof ACCTextStickerView *editingStickerView;

- (instancetype)initWithOptions:(ACCTextStickerEditAbilityOptions)viewOptions;

- (void)startEditStickerView:(ACCTextStickerView *)textView;
- (void)startEditStickerView:(ACCTextStickerView *)textView inputMode:(ACCTextStickerEditEnterInputMode)inputMode;

@property (nonatomic, weak) AWEVideoPublishViewModel *publishViewModel; // 之前的搜索组件用来抽帧的数据，后续解耦
@property (nonatomic, assign) BOOL fromTextMode;

@property (nonatomic, copy) void (^didSelectedColorBlock) (AWEStoryColor *selectColor, NSIndexPath *indexPath);
@property (nonatomic, copy) void (^didSelectedFontBlock) (AWEStoryFontModel *model, NSIndexPath *indexPath);
@property (nonatomic, copy) void (^didChangeStyleBlock) (AWEStoryTextStyle style);
@property (nonatomic, copy) void (^didChangeAlignmentBlock) (AWEStoryTextAlignmentStyle style);
@property (nonatomic, copy) void (^didSelectTTSAudio) (NSString *audioFilePath, NSString *audioSpeaker);
@property (nonatomic, copy) void (^didTapFinishCallback)(NSString *audioFilePath, NSString *speakerID, NSString *speakerName);
@property (nonatomic, copy) void (^didTapCancelCallback)(void);

@property (nonatomic, copy) void (^onEditFinishedBlock)(ACCTextStickerView *, BOOL fromSaveButton);
@property (nonatomic, copy) void (^finishEditAnimationBlock)(ACCTextStickerView *);
@property (nonatomic, copy) void (^startEditBlock)(ACCTextStickerView *);
@property (nonatomic, copy) void (^startSelectingTTSAudioBlock)(void);
@property (nonatomic, copy) AWETextStickerReadModel * (^getTextReaderModelBlock)(void);

@property (nonatomic, copy) NSInteger (^stickerTotalHashtagBindCountProvider)(void);
@property (nonatomic, copy) NSInteger (^stickerTotalMentionBindCountProvider)(void);

@property (nonatomic, copy) void (^triggeredSocialEntraceBlock)(BOOL isFromToolbar, BOOL isMention);
@property (nonatomic, copy) void (^didSelectedToolbarColorItemBlock) (BOOL willShowColorPannel);

@property (nonatomic, strong) AWETextStickerStylePreferenceModel *stylePreferenceModel;

@end

NS_ASSUME_NONNULL_END
