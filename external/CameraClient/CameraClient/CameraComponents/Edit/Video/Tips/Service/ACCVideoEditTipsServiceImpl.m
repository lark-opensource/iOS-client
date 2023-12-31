//
//  ACCVideoEditTipsServiceImpl.m
//  CameraClient
//
//  Created by yangying on 2020/12/14.
//

#import "ACCVideoEditTipsServiceImpl.h"
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCBubbleDefinition.h"
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCBubbleProtocol.h"
#import "AWEVideoEditDefine.h"
#import "AWEImageAndTitleBubble.h"
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreationKitArch/ACCStudioDefines.h>

@interface ACCVideoEditTipsServiceImpl()

@property (nonatomic, strong) UIView *functionBubble;
@property (nonatomic, strong) AWEImageAndTitleBubble *imageTitleBubble;
@property (nonatomic, strong, readwrite) RACSignal *showMusicBubbleSignal;
@property (nonatomic, strong, readwrite) RACBehaviorSubject *showMusicBubbleSubject;

@property (nonatomic, strong, readwrite) RACSignal *showQuickPublishBubbleSignal;
@property (nonatomic, strong, readwrite) RACBehaviorSubject *showQuickPublishBubbleSubject;

@property (nonatomic, strong) RACSubject *showCanvasInteractionGudeSubject;

@property (nonatomic, strong) RACSubject *showImageAlbumSwitchModeBubbleSubject;

@property (nonatomic, strong) RACSubject *showSmartMovieBubbleSubject;

@property (nonatomic, strong) RACSubject *showImageAlbumSlideGuideSubject;

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@end

@implementation ACCVideoEditTipsServiceImpl

@synthesize showedValue = _showedValue;

- (void)dealloc {
    [_showMusicBubbleSubject sendCompleted];
    [_showSmartMovieBubbleSubject sendCompleted];
    [_showQuickPublishBubbleSubject sendCompleted];
    [_showCanvasInteractionGudeSubject sendCompleted];
    [_showImageAlbumSwitchModeBubbleSubject sendCompleted];
    [_showImageAlbumSlideGuideSubject sendCompleted];
}

- (void)showFunctionBubbleWithContent:(NSString *)content
                              forView:(UIView *)view
                        containerView:(UIView *)containerView
                            mediaView:(UIView *)mediaView
                     anchorAdjustment:(CGPoint)adjustment
                          inDirection:(ACCBubbleManagerDirection)bubbleDirection
                         functionType:(AWEStudioEditFunctionType)type
{
    if ([AWEXScreenAdaptManager needAdaptScreen] && ACCBubbleManagerDirectionUp == bubbleDirection && [UIDevice acc_isIPhone]) {
        CGRect frame = mediaView.frame;
        CGRect viewFrame = [view.superview convertRect:view.frame toView:mediaView.superview];
        CGFloat offset = CGRectGetMinY(viewFrame) - CGRectGetMaxY(frame) + 4;
        adjustment = CGPointMake(adjustment.x, adjustment.y - offset);
    }
    self.functionBubble = [ACCBubble() showBubble:content forView:view inContainerView:containerView anchorAdjustment:adjustment inDirection:(ACCBubbleDirection)bubbleDirection bgStyle:([self isDarkBackGround] ? ACCBubbleBGStyleDark:ACCBubbleBGStyleDefault) completion:^{}];
    self.functionBubble.tag = type;
    [ACCBubble() bubble:self.functionBubble supportTapToDismiss:YES];
    if (type == AWEStudioEditFunctionLiveSticker) {
        [ACCBubble() bubble:self.functionBubble textAlignment:NSTextAlignmentLeft];
        [ACCBubble() bubble:self.functionBubble textNumberOfLines:2];
    }
    [self.functionBubble acc_addSingleTapRecognizerWithTarget:self action:@selector(didTappedFunctionBubble)];
    
    [self.subscription performEventSelector:@selector(tipService:didShowFunctionBubbleWithFunctionType:) realPerformer:^(id<ACCVideoEditTipsServiceSubscriber> subscriber) {
        [subscriber tipService:self didShowFunctionBubbleWithFunctionType:type];
    }];
}

- (void)showImageBubble:(UIImage *)image
                forView:(UIView *)targetView
          containerView:(UIView *)containerView
              mediaView:(UIView *)mediaView
            inDirection:(AWEImageAndTitleBubbleDirection)direction
               subtitle:(NSString *)title
           functionType:(AWEStudioEditFunctionType)type
{
    
    CGPoint anchorAdjustment = CGPointZero;
    switch (direction) {
        case AWEImageAndTitleBubbleDirectionUp:
        {
            anchorAdjustment = CGPointMake(0, 0);
            if ([AWEXScreenAdaptManager needAdaptScreen]) {
                CGRect frame = mediaView.frame;
                CGRect viewFrame = [targetView.superview convertRect:targetView.frame toView:mediaView.superview];
                CGFloat offset = CGRectGetMinY(viewFrame) - CGRectGetMaxY(frame) + 4;
                anchorAdjustment = CGPointMake(anchorAdjustment.y, anchorAdjustment.y - offset);
            }
            break;
        }
        case AWEImageAndTitleBubbleDirectionDown:
            anchorAdjustment = CGPointMake(0, -5); break;
        default:
            break;
    }
    self.imageTitleBubble = [[AWEImageAndTitleBubble alloc] initWithTitle: ACCLocalizedString(@"edit_page_prompt_music_ai", @"推荐配乐") subTitle:title image:image forView:targetView inContainerView:containerView anchorAdjustment:anchorAdjustment direction:direction isDarkBackGround:[self isDarkBackGround]];
    [self.imageTitleBubble showWithAnimated:YES];
    [self.imageTitleBubble acc_addSingleTapRecognizerWithTarget:self action:@selector(didTappedImageTitleBubble)];
    self.imageTitleBubble.tag = type;
    
    [self.subscription performEventSelector:@selector(tipService:didShowImageBubbleWithFunctionType:) realPerformer:^(id<ACCVideoEditTipsServiceSubscriber> subscriber) {
        [subscriber tipService:self didShowImageBubbleWithFunctionType:type];
    }];
}

- (void)didTappedImageTitleBubble
{
    [self dismissFunctionBubbles];
    [self.subscription performEventSelector:@selector(tipService:didTappedImageBubbleWithFunctionType:) realPerformer:^(id<ACCVideoEditTipsServiceSubscriber> subscriber) {
        [subscriber tipService:self didTappedImageBubbleWithFunctionType:self.imageTitleBubble.tag];
    }];
}

- (void)didTappedFunctionBubble
{
    [self dismissFunctionBubbles];
    [self.subscription performEventSelector:@selector(tipService:didTappedFunctionBubbleWithFunctionType:) realPerformer:^(id<ACCVideoEditTipsServiceSubscriber> subscriber) {
        [subscriber tipService:self didTappedFunctionBubbleWithFunctionType:self.functionBubble.tag];
    }];
}

- (void)dismissFunctionBubbles
{
    if (self.functionBubble) {
        [ACCBubble() tapToDismissWithBubble:self.functionBubble];
        self.functionBubble = nil;
    }
    
    if (self.imageTitleBubble) {
        [self.imageTitleBubble dismissWithAnimated:YES];
        self.imageTitleBubble = nil;
    }
}

- (BOOL)isDarkBackGround
{
    if (self.repository.repoVideoInfo.sizeOfVideo) {
        CGSize videoSize = [self.repository.repoVideoInfo.sizeOfVideo CGSizeValue];
        if (ACC_FLOAT_EQUAL_ZERO(videoSize.height)) {
            return NO;
        }
        
        if (videoSize.width / videoSize.height - 9.0 / 16.0 > 0.1) {
            return YES;
        }
    }
    
    return NO;
}

- (void)saveShowedFunctionsByType:(AWEStudioEditFunctionType)type
{
    self.showedValue = self.showedValue | (1 << type);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [ACCCache() setObject:@(self.showedValue) forKey:kAWEStudioEditFunctionToastShowedValuesKey];
    });
}

- (RACSignal *)showMusicBubbleSignal
{
    return self.showMusicBubbleSubject;
}

- (RACBehaviorSubject *)showMusicBubbleSubject
{
    if (!_showMusicBubbleSubject) {
        _showMusicBubbleSubject = [RACBehaviorSubject subject];
    }
    return _showMusicBubbleSubject;
}

- (RACSignal *)showQuickPublishBubbleSignal
{
    return self.showQuickPublishBubbleSubject;
}

- (RACBehaviorSubject *)showQuickPublishBubbleSubject
{
    if (!_showQuickPublishBubbleSubject) {
        _showQuickPublishBubbleSubject = [RACBehaviorSubject subject];
    }
    return _showQuickPublishBubbleSubject;
}

- (void)sendShowMusicBubbleSignalByType:(ACCMusicBubbleType)type
{
    [self.showMusicBubbleSubject sendNext:@(type)];
}

- (void)sendShowQuickPublishBubbleSignal
{
    [self.showQuickPublishBubbleSubject sendNext:@(YES)];
}

- (RACSignal *)showCanvasInteractionGudeSignal
{
    return self.showCanvasInteractionGudeSubject;
}

- (RACSubject *)showCanvasInteractionGudeSubject
{
    if (!_showCanvasInteractionGudeSubject) {
        _showCanvasInteractionGudeSubject = [RACSubject subject];
    }
    return _showCanvasInteractionGudeSubject;
}

- (void)sendShowCanvasInteractionGuideSignal
{
    [self.showCanvasInteractionGudeSubject sendNext:@(YES)];
}

- (RACSignal *)showImageAlbumSwitchModeBubbleSignal
{
    return self.showImageAlbumSwitchModeBubbleSubject;
}

- (RACSubject *)showImageAlbumSwitchModeBubbleSubject
{
    if (!_showImageAlbumSwitchModeBubbleSubject) {
        _showImageAlbumSwitchModeBubbleSubject = [RACSubject subject];
    }
    return _showImageAlbumSwitchModeBubbleSubject;
}

- (void)sendShowImageAlbumSwitchModeBubbleSignal
{
    [self.showImageAlbumSwitchModeBubbleSubject sendNext:nil];
}

- (void)sendShowSmartMovieBubbleSignal
{
    [self.showSmartMovieBubbleSubject sendNext:nil];
}

- (RACSignal *)showSmartMovieBubbleSignal
{
    return self.showSmartMovieBubbleSubject;
}

- (RACSubject *)showSmartMovieBubbleSubject
{
    if (!_showSmartMovieBubbleSubject) {
        _showSmartMovieBubbleSubject = [RACSubject subject];
    }
    return _showSmartMovieBubbleSubject;
}

- (RACSignal *)showImageAlbumSlideGuideSignal
{
    return self.showImageAlbumSlideGuideSubject;
}

- (RACSubject *)showImageAlbumSlideGuideSubject
{
    if (!_showImageAlbumSlideGuideSubject) {
        _showImageAlbumSlideGuideSubject = [RACSubject subject];
    }
    return _showImageAlbumSlideGuideSubject;
}

- (void)sendShowImageAlbumSlideGuideSignal
{
    [self.showImageAlbumSlideGuideSubject sendNext:nil];
}

#pragma mark - subscription

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCVideoEditTipsServiceSubscriber>)subscriber {
    [self.subscription addSubscriber:subscriber];
}


@end
