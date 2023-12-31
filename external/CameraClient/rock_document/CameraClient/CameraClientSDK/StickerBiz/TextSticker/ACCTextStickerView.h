//
//  ACCTextStickerView.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/16.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import "ACCTextStickerTextView.h"
#import "ACCStickerEditContentProtocol.h"
#import "ACCVideoDataClipRangeStorageModel.h"
#import <CreationKitArch/ACCTextStickerExtraModel.h>

NS_ASSUME_NONNULL_BEGIN
@class AWETextExtra, ACCSocialStickeMentionBindingModel, ACCTextStickerInputController;

typedef NS_OPTIONS(NSUInteger, ACCTextStickerViewAbilityOptions) {
    ACCTextStickerViewAbilityOptionsNone           = 0,
    ACCTextStickerViewAbilityOptionsSupportSocial  = 1 << 0
};

@interface ACCTextStickerView : UIView <ACCStickerEditContentProtocol>

@property (nonatomic, strong, readonly) AWEStoryTextImageModel *textModel;
@property (nonatomic, strong, readonly) ACCTextStickerTextView *textView;
@property (nonatomic, strong, readonly) ACCTextStickerInputController *_Nullable inputController;

@property (nonatomic, strong, nullable) NSString *textStickerId;
@property (nonatomic, assign) NSInteger stickerID;
@property (nonatomic, strong) ACCVideoDataClipRangeStorageModel *timeEditingRange;
@property (nonatomic, copy) void (^textChangedBlock) (NSString *content);
@property (nonatomic, copy) void (^_Nullable searchKeyworkChangedBlock) (BOOL shouldSearch, ACCTextStickerExtraType searchType, NSString *keyword);
@property (nonatomic, copy) void (^willChangeTextInRangeBlock)(NSString *replacementText, NSRange range);
@property (nonatomic, copy) void (^textSelectedChangeBlock) (NSRange range);

- (void)updateDisplay;
- (instancetype)initWithTextInfo:(AWEStoryTextImageModel *)model options:(ACCTextStickerViewAbilityOptions)options;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)transportToEditWithSuperView:(UIView *)superView animation:(void (^)(void))animationBlock animationDuration:(CGFloat)duration;
- (void)restoreToSuperView:(UIView *)superView animationDuration:(CGFloat)duration animationBlock:(void (^)(void))animationBlock completion:(void (^)(void))completion;
- (void)updateBubbleStatusAfterEdit;


@end


NS_ASSUME_NONNULL_END
