//
//  AWEStickerPickerControllerDuetPropBubblePlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by zhuopeijin on 2021/3/23.
//

#import "AWEStickerPickerControllerDuetPropBubblePlugin.h"

#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCMusicRecommendPropBubbleView.h"
#import "AWERecorderTipsAndBubbleManager.h"

#import "ACCPropViewModel.h"


@interface AWEStickerPickerControllerDuetPropBubblePlugin ()

@property (nonatomic, strong) ACCPropViewModel *propViewModel;
@property (nonatomic, weak) AWEStickerPickerController *propPickerController;
@property (nonatomic, strong) id<ACCRecorderViewContainer> recorderViewContainer;

@property (nonatomic, strong) IESEffectModel *bubbleEffect; // effect show on Bubble

@end

@implementation AWEStickerPickerControllerDuetPropBubblePlugin

- (instancetype)initWithViewModel:(ACCPropViewModel *)propViewModel
                     bubbleEffect:(IESEffectModel *) bubbleEffect
                    viewContainer:(id<ACCRecorderViewContainer>)recorderViewContainer {
    
    self = [super init];

    if (self) {
        if ([bubbleEffect.childrenIds count] > 0) {
            for (IESEffectModel *child in bubbleEffect.childrenEffects){
                if (child.downloaded) {
                    _bubbleEffect = child;
                    break;
                }
            }
        } else {
            _bubbleEffect = bubbleEffect;
        }
        _propViewModel = propViewModel;
        _recorderViewContainer = recorderViewContainer;
        if ([self shouldShowBubble]) {
            [AWERecorderTipsAndBubbleManager shareInstance].needShowDuetWithPropBubble = YES;
        } else {
            [AWERecorderTipsAndBubbleManager shareInstance].needShowDuetWithPropBubble = NO;
        }
    }
    return self;
}

#pragma mark show bubble

- (BOOL)shouldShowBubble
{
    if (self.bubbleEffect == nil) { return NO; }
    if (![[AWERecorderTipsAndBubbleManager shareInstance] shouldShowDuetWithPropBubbleWithInputData:self.propViewModel.inputData]) {
        return NO;
    }

    return YES;
}

- (void)tryToShowBubble
{
    if ([self shouldShowBubble]) {
        // show bubble
        [self showDuetWithPropBubble];
    }
}

- (void)showDuetWithPropBubble
{
    @weakify(self);
    ACCUseRecommendPropBlock usePropBlock = ^(IESEffectModel * _Nullable effectModel){
        if (!effectModel) {
            return;
        }
        [[AWERecorderTipsAndBubbleManager shareInstance] removeDuetWithPropBubble];
        @strongify(self);
        [self applyProp];
    };
    
    ACCMusicRecommendPropBubbleView *bubbleView = [[ACCMusicRecommendPropBubbleView alloc] initWithPropModel:self.bubbleEffect usePropBlock:usePropBlock];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(applyProp)];
    [bubbleView addGestureRecognizer:tapGes];
    
    UIView *stickerSwitchButton = [self.recorderViewContainer.layoutManager viewForType:ACCViewTypeStickerSwitchButton];
    
    [[AWERecorderTipsAndBubbleManager shareInstance] showDuetWithPropBubbleForTargetView:stickerSwitchButton bubbleView:bubbleView containerView:self.recorderViewContainer.interactionView direction:ACCBubbleDirectionUp bubbleDismissBlock:nil];
}

#pragma mark apply prop

- (void) applyProp
{
    // already apply
    IESEffectModel *currentUsingSticker = self.propViewModel.currentSticker;
    if (currentUsingSticker && ![currentUsingSticker.sourceIdentifier isEqualToString:self.bubbleEffect.effectIdentifier]) {
        return;
    }
    
    // check whether the sticker can be selected
    if ([self.propPickerController.delegate respondsToSelector:@selector(stickerPickerController:shouldSelectSticker:)]) {
        BOOL shouldApplyProp = [self.propPickerController.delegate stickerPickerController:self.propPickerController shouldSelectSticker:self.bubbleEffect];
        if (!shouldApplyProp) {
            return;
        }
    }

    // apply prop
    if (self.additionalApplyPropBlock) {
        ACCBLOCK_INVOKE(self.additionalApplyPropBlock, self.bubbleEffect);
    }

    // dismiss bubble
    [[AWERecorderTipsAndBubbleManager shareInstance] removeDuetWithPropBubble];
}

#pragma mark - AWEStickerPickerControllerPluginProtocol

- (void)controllerDidFinishLoadStickerCategories:(AWEStickerPickerController *)controller
{
    self.propPickerController = controller;
    [self tryToShowBubble];
}

@end
