//
//  ACCStickerBubbleHelper.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/8.
//

#import "ACCStickerBubbleHelper.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "AWEEditStickerBubbleManager.h"
#import <CreationKitArch/AWEStudioExcludeSelfView.h>
#import <CreativeKitSticker/ACCPlayerAdaptionContainer+Bubble.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCStickerBizDefines.h"
#import "ACCStickerEditContentProtocol.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerBubbleDYConfig.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

NSString *const kAWEEditTextReadingAnimationCacheNewKey = @"kAWEEditTextReadingAnimationCacheNewKey";

@interface ACCStickerBubbleHelper ()

@property (nonatomic, weak) ACCBaseStickerView *stickerView;

@property (nonatomic, strong) NSArray <ACCStickerBubbleConfig *> *bubbleActionList;
@property (nonatomic, strong) NSArray<AWEEditStickerBubbleItem *> *bubbleItems;
@property (nonatomic, strong) AWEEditStickerBubbleManager *bubble;

@end

@implementation ACCStickerBubbleHelper

- (instancetype)initWithWeakReferenceOfStickerView:(ACCBaseStickerView *)stickerView bubbleActionList:(nonnull NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSArray *validBubbleActionList = [bubbleActionList copy];
    if (validBubbleActionList.count == 0) {
        return nil;
    }
    self = [super init];
    if (self) {
        _stickerView = stickerView;
        _bubbleActionList = validBubbleActionList;
    }
    return self;
}

- (void)showBubbleAtPoint:(CGPoint)point
{
    [self _showBubbleMenuAtPoint:point autoDismiss:YES];
    [self handleContentWhenBubbleChanged:YES];
}

- (void)hideAnimated:(BOOL)animated
{
    [self.bubble setBubbleVisible:NO animated:animated];
    [self hideBubbleMenu:animated];
    [self handleContentWhenBubbleChanged:NO];
}

- (void)updateBubbleWithTag:(NSString *)tag title:(NSString *)title image:(UIImage *)image
{
    if (!tag || (!title && !image)) {
        return;
    }
    [self.bubbleItems enumerateObjectsUsingBlock:^(AWEEditStickerBubbleItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.actionTag isEqualToString:tag]) {
            if (title) {
                obj.title = title;
            }
            if (image) {
                obj.image = image;
            }
        }
    }];
}

- (void)updateBubbleActionListIfNeeded:(nonnull NSArray<ACCStickerBubbleConfig *> *)bubbleActionList {
    
}

- (void)handleContentWhenBubbleChanged:(BOOL)show
{
    UIView<ACCStickerEditContentProtocol> *contentView = (UIView<ACCStickerEditContentProtocol> *)self.stickerView.contentView;
    if ([contentView respondsToSelector:@selector(bubbleChanged:)]) {
        [contentView bubbleChanged:show];
    }
}

#pragma mark - Bubble

- (void)deSelectStickerView
{
    [self.stickerView doDeselect];
}

- (void)_showBubbleMenuAtPoint:(CGPoint)point autoDismiss:(BOOL)autoDismiss
{
    [self _showBubbleMenuAtPoint:point];
    if (autoDismiss) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSTimeInterval delay = 3;
        if (UIAccessibilityIsVoiceOverRunning()) {
            delay = 30;
        }
        [self performSelector:@selector(deSelectStickerView) withObject:nil afterDelay:delay];
    }
}

- (void)_showBubbleMenuAtPoint:(CGPoint)point
{
    // show bubble
    UIView *overlayView = self.stickerView.stickerContainer.overlayView;
    UIView *parentView = nil;
    // very hack, MUST BE FIXED by someone
    if ([self.stickerView.stickerContainer isKindOfClass:[ACCPlayerAdaptionContainer class]]) {
        parentView = ((ACCPlayerAdaptionContainer *)self.stickerView.stickerContainer).bubbleContainerView;
        if (!parentView) {
            parentView = [[AWEStudioExcludeSelfView alloc] initWithFrame:self.stickerView.stickerContainer.playerRect];
            [overlayView addSubview:parentView];
            [((ACCPlayerAdaptionContainer *)self.stickerView.stickerContainer) setBubbleContainerView:parentView];
        }
    }
    CGPoint center = self.stickerView.center;
    CGSize size = self.stickerView.bounds.size;
    
    CGAffineTransform transform = self.stickerView.transform;
    CGFloat scale = sqrt(transform.a * transform.a + transform.c * transform.c);
    ACCStickerConfig *config = self.stickerView.config;
    
    CGRect frameForTransformIdentity = CGRectMake(
                                                  center.x - size.width/2 - (config.boxPadding.left/scale),
                                                  center.y - size.height/2 - (config.boxPadding.top/scale),
                                                  size.width + (config.boxPadding.left+config.boxPadding.right)/scale,
                                                  size.height + (config.boxPadding.top+config.boxPadding.bottom)/scale
                                                  );
    
    CGRect hintFrame = CGRectInset(frameForTransformIdentity, -6.0f, -6.0f);
    
    CGPoint realPoint = [[self.stickerView.stickerContainer containerView] convertPoint:point fromView:parentView];
    hintFrame = [[self.stickerView.stickerContainer containerView] convertRect:hintFrame toView:parentView];
    
    [self.bubble setRect:hintFrame touchPoint:realPoint transform:transform inParentView:parentView];
    [self.bubble setBubbleVisible:YES animated:YES];
}

- (void)hideBubbleMenu:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.bubble setBubbleVisible:NO animated:animated];
}

- (AWEEditStickerBubbleManager *)bubble
{
    if (!_bubble) {
        
        NSString *bubbleName = NSStringFromClass([self.stickerView.contentView class]);
        // 重要版本周期内上车，先包在需求里稳妥一些 后续一起删除
        if (ACCConfigBool(kConfigBool_enable_image_album_story)) {
            bubbleName = ACCStickerEditingBubbleManagerName;
        }
        AWEEditStickerBubbleManager *bubble = [AWEEditStickerBubbleManager managerWithName:bubbleName];

        if (!self.bubbleItems) {
            NSMutableArray *items = [NSMutableArray array];
            for (ACCStickerBubbleConfig *config in self.bubbleActionList) {
                if ([config isKindOfClass:[ACCStickerBubbleDYConfig class]]) {
                    [items acc_addObject:[self bubbleItemWithDYConfig:(ACCStickerBubbleDYConfig *)config]];
                } else if (config.actionType == ACCStickerBubbleActionBizEdit) {
                    [items addObject:[self editBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizSelectTime) {
                    [items addObject:[self selectTimeBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizPin) {
                    [items addObject:[self pinBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizEditAutoCaptions) {
                    [items addObject:[self editAutoCaptionsBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizDelete) {
                    [items addObject:[self deleteBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizTextRead) {
                    [items addObject:[self textReadBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizTextReadCancel) {
                    [items addObject:[self textReadCancelBubbleItemWithCallback:config.callback]];
                } else if (config.actionType == ACCStickerBubbleActionBizPreview) {
                    [items acc_addObject:[self previewBubbleItemWithCallback:config.callback]];
                }
            }
            self.bubbleItems = items.copy;
        }
        bubble.bubbleItems = self.bubbleItems;
        _bubble = bubble;
    }
    return _bubble;
}

- (AWEEditStickerBubbleItem *)pinBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    return [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icEditPageStickerPin") title:ACCLocalizedString(@"creation_edit_sticker_pin", @"Pin") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizPin);
        }
    }];
}

- (AWEEditStickerBubbleItem *)bubbleItemWithDYConfig:(ACCStickerBubbleDYConfig *)config
{
    @weakify(self);
    return [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(config.accResourceImageName) title:config.title actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (config.callback != NULL) {
            config.callback(ACCStickerBubbleActionBizUndefined);
        }
    }];
}

- (AWEEditStickerBubbleItem *)editBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    return [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerEditNew") title:ACCLocalizedString(@"creation_edit_text_edit", @"Edit") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizEdit);
        }
    }];
}

- (AWEEditStickerBubbleItem *)selectTimeBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    return [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerTimeNew") title:ACCLocalizedString(@"creation_edit_sticker_duration", @"Set duration") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizSelectTime);
        }
    }];
}

- (AWEEditStickerBubbleItem *)editAutoCaptionsBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    return [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerEditNew") title:ACCLocalizedString(@"auto_caption_edit_subtitle", @"Edit captions") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizEditAutoCaptions);
        }
    }];
}

- (AWEEditStickerBubbleItem *)deleteBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    return [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCaptionDelete") title:ACCLocalizedString(@"delete", @"") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizDelete);
        }
    }];
}

- (AWEEditStickerBubbleItem *)textReadBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    AWEEditStickerBubbleItem *bubbleItem = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icTextStickerRead") title:ACCLocalizedString(@"creation_edit_text_reading_entrance", @"Text-to-speech") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizTextRead);
        }
    }];
    
    bubbleItem.actionTag = @"text_read";
    bubbleItem.showShakeAnimation = ![ACCCache() boolForKey:kAWEEditTextReadingAnimationCacheNewKey];
    bubbleItem.shakeAniPerformedBlock = ^{
        [ACCCache() setBool:YES forKey:kAWEEditTextReadingAnimationCacheNewKey];
    };
    return bubbleItem;
}

- (AWEEditStickerBubbleItem *)textReadCancelBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    AWEEditStickerBubbleItem *bubbleItem = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icTextStickerRead") title:ACCLocalizedString(@"creation_edit_text_reading_entrance_cancel", @"Remove") actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            callback(ACCStickerBubbleActionBizTextRead);
        }
    }];
    
    bubbleItem.actionTag = @"text_read";
    return bubbleItem;
}

- (AWEEditStickerBubbleItem *)previewBubbleItemWithCallback:(void (^)(ACCStickerBubbleAction actionType))callback
{
    @weakify(self);
    AWEEditStickerBubbleItem *bubbleItem = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"ic_video_reply_preview_play")
                                                                                     title:@"查看视频"
                                                                               actionBlock:^{
        @strongify(self);
        [self hideAnimated:NO];
        [self.stickerView doDeselect];
        if (callback != NULL) {
            ACCBLOCK_INVOKE(callback, ACCStickerBubbleActionBizPreview);
        }
    }];
    
    bubbleItem.actionTag = @"preview";
    return bubbleItem;
}

@end
