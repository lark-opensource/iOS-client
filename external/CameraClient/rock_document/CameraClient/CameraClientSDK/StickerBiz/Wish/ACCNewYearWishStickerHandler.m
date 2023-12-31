//
//  ACCNewYearWishStickerHandler.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/1.
//

#import "ACCNewYearWishStickerHandler.h"
#import "ACCNewYearWishModuleEditView.h"
#import "ACCNewYearWishTextEditView.h"
#import "ACCRepoActivityModel.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCTextStickerView.h"
#import "AWERepoTrackModel.h"
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import "IESInfoSticker+ACCAdditions.h"
#import "ACCEditActivityDataHelperProtocol.h"

typedef NS_ENUM(NSUInteger, ACCNewYearWishStickerType) {
    ACCNewYearWishStickerTypeIcon = 0, // 头像
    ACCNewYearWishStickerTypeTitle = 1, // 标题
};

static CGFloat const kCCNewYearWishAvatarIconStickerLength = 72.f;
static CGFloat const kCCNewYearWishAvatarTitleStickerLength = 339.f;
static NSString *const kACCNewYearWishTextTypeKey = @"biztype";
static NSString *const kACCNewYearWishStickerTypeKey = @"wish_type";

@interface ACCNewYearWishStickerHandler()

@property (nonatomic, weak) ACCNewYearWishModuleEditView *moduleEditView;
@property (nonatomic, weak) ACCNewYearWishTextEditView *textEditView;

@property (nonatomic, weak) UILabel *guideLabel;
@property (nonatomic, weak) ACCTextStickerView *textStickerView;

@end

@implementation ACCNewYearWishStickerHandler

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx
{
    
}

- (void)autoAddStickerAndGuide
{
    [self.player removeStickerWithType:ACCEditEmbeddedStickerTypeWish];
    
    [self p_configWishSticker:ACCNewYearWishStickerTypeTitle];
    [self p_configWishSticker:ACCNewYearWishStickerTypeIcon];
    
    [self.stickerContainerView.allStickerViews acc_forEach:^(ACCStickerViewType  _Nonnull obj) {
        ACCTextStickerView *textStickerView = (ACCTextStickerView *)obj.contentView;
        if ([textStickerView isKindOfClass:ACCTextStickerView.class]) {
            NSString *bizType = [textStickerView.textModel.extra acc_stringValueForKey:kACCNewYearWishTextTypeKey];
            if ([bizType isEqualToString:@"wish"]) {
                self.textStickerView = textStickerView;
            }
        }
    }];
    
    if (!self.guideLabel) {
        UILabel *guideLabel = [[UILabel alloc] init];
        guideLabel.text = @"点击输入心愿";
        guideLabel.textAlignment = NSTextAlignmentCenter;
        guideLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.6];
        guideLabel.font = [UIFont acc_systemFontOfSize:32.f weight:ACCFontWeightMedium];
        [self.stickerContainerView.overlayView addSubview:guideLabel];
        self.guideLabel = guideLabel;
        ACCMasMaker(guideLabel, {
            make.center.equalTo(self.stickerContainerView.overlayView);
            make.width.equalTo(@(200.f));
            make.height.equalTo(@(45.f));
        });
    }
    [self updateGuideLabelStatus];
}

- (void)updateGuideLabelStatus
{
    self.guideLabel.hidden = self.wishModel.text.length > 0;
}

- (void)p_configWishSticker:(ACCNewYearWishStickerType)stickerType
{
    NSDictionary *userInfo = ({
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        info.acc_stickerType = ACCEditEmbeddedStickerTypeWish;
        info[kACCStickerUUIDKey] = [NSUUID UUID].UUIDString ?: @"";
        info[kACCNewYearWishStickerTypeKey] = @(stickerType);
        [info copy];
    });
    NSString *iconPath = [AWEDraftUtils generatePathFromTaskId:self.publishModel.repoDraft.taskID name:self.wishModel.avatarPath];
    if (stickerType == ACCNewYearWishStickerTypeTitle) {
        IESEffectModel *model = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:self.wishModel.effectId];
        let dataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCNewYearWishDataHelperProtocol) class];
        iconPath = [dataHelper fetchImageFileInFolder:model.filePath];
        if (!iconPath) {
            return;
        }
    }
    NSInteger stickerId = [self.player addInfoSticker:iconPath withEffectInfo:nil userInfo:userInfo];
    IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
    [self.player getStickerId:stickerId props:props];
    [self.player setSticker:stickerId offsetX:props.offsetX offsetY:props.offsetY+158.f];
    [self.player setSticker:stickerId startTime:0.f duration:self.player.stickerInitialEndTime];
    
    CGSize stickerSize = [self.player getInfoStickerSize:stickerId];
    if (stickerSize.width > 0 && stickerSize.width > 0) {
        CGFloat aspectRatio = MAX(stickerSize.width,stickerSize.height) / (stickerType == ACCNewYearWishStickerTypeIcon ? kCCNewYearWishAvatarIconStickerLength : kCCNewYearWishAvatarTitleStickerLength);
        [self.player setStickerScale:stickerId scale:1/aspectRatio];
    }
}

- (void)startEditTextStickerView:(ACCTextStickerView *)stickerView
{
    _textStickerView = stickerView;
    _textStickerView.textModel.extra = @{
        kACCNewYearWishTextTypeKey : @"wish"
    };
    self.guideLabel.hidden = YES;
}

- (void)endEditTextStickerView:(ACCTextStickerView *)stickerView
{
    _textStickerView = stickerView;
    _textStickerView.textModel.extra = @{
        kACCNewYearWishTextTypeKey : @"wish"
    };
    self.wishModel.text = [stickerView.textView.text btd_trimmed];
    [self updateGuideLabelStatus];
    NSMutableDictionary *info = [self.publishModel.repoTrack.schemaTrackParmForActivity mutableCopy];
    [info acc_setObject:self.wishModel.text forKey:@"wish_text"];
    
    NSInteger officialIndex = [self p_findTargetIndex:ACCConfigArray(kConfigArray_new_year_recommend_wish)];
    self.wishModel.officialText = officialIndex != NSNotFound;
    self.publishModel.repoTrack.schemaTrackParmForActivity = [info copy];
}

- (void)startEditWishModule
{
    if (!self.moduleEditView) {
        ACCNewYearWishModuleEditView *editView = [[ACCNewYearWishModuleEditView alloc] initWithFrame:self.stickerContainerView.overlayView.bounds];
        editView.player = self.player;
        editView.publishModel = self.publishModel;
        @weakify(self);
        editView.onModuleSelected = ^(NSString *effectId, NSInteger index){
            @strongify(self);
            NSMutableDictionary *info = [self.publishModel.repoTrack.schemaTrackParmForActivity mutableCopy];
            [info acc_setObject:effectId forKey:@"wish_background"];
            self.publishModel.repoTrack.schemaTrackParmForActivity = [info copy];
            [self autoAddStickerAndGuide];
            self.guideLabel.hidden = YES;
        };
        editView.onTrackEvent = ^(NSString *event, NSDictionary *extra) {
            @strongify(self);
            [self trackEvent:event extra:extra];
        };
        editView.dismissBlock = ^{
            @strongify(self);
            [self.moduleEditView removeFromSuperview];
            [self.delegate editStatusChanged:NO];
            [self updateGuideLabelStatus];
        };
        [self.stickerContainerView.overlayView addSubview:editView];
        [editView performAnimation:YES];
        self.moduleEditView = editView;
        self.guideLabel.hidden = YES;
    }
    [self.delegate editStatusChanged:YES];
    [self trackEvent:@"enter_yd_wish_background" extra:@{
        @"enter_method" : @"click_background_button"
    }];
}

- (void)startEditWishText
{
    if (!self.textEditView) {
        ACCNewYearWishTextEditView *editView = [[ACCNewYearWishTextEditView alloc] initWithFrame:self.stickerContainerView.overlayView.bounds];
        editView.titles = ACCConfigArray(kConfigArray_new_year_recommend_wish);
        @weakify(self);
        editView.onTitleSelected = ^(NSString *title, NSInteger index) {
            @strongify(self);
            if (self.textStickerView) {
                self.textStickerView.textView.text = title;
                [self.textStickerView updateDisplay];
            } else {
                [self.delegate addTextSticker:title];
            }
            if (![title isEqualToString:self.wishModel.text]) {
                self.wishModel.text = title;
                self.textStickerView.textModel.content = title;
                [self.delegate editWishTextDidChanged:self.textStickerView];
            }
            self.wishModel.officialText = YES;
            [self trackEvent:@"choose_yd_wish_confirm" extra:@{
                @"wish_content" : title ? : @"",
                @"enter_method" : @"click_outside"
            }];
        };
        editView.dismissBlock = ^{
            @strongify(self);
            [self.textEditView removeFromSuperview];
            [self.delegate editStatusChanged:NO];
            [self updateGuideLabelStatus];
        };
        [self.stickerContainerView.overlayView addSubview:editView];
        editView.selectedIndex = [self p_findTargetIndex:ACCConfigArray(kConfigArray_new_year_recommend_wish)];
        [editView performAnimation:YES];
        self.guideLabel.hidden = YES;
        self.textEditView = editView;
    }
    [self.delegate editStatusChanged:YES];
    [self trackEvent:@"enter_yd_wish_warehouse" extra:@{
        @"enter_method" : @"click_wish_button"
    }];
}

- (NSInteger)p_findTargetIndex:(NSArray<NSString *> *)titles
{
    __block NSInteger index = NSNotFound;
    NSString *targetStr = [self.textStickerView.textView.text btd_trimmed];
    [titles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([targetStr isEqualToString:obj]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (void)trackEvent:(NSString *)event extra:(NSDictionary *)extra
{
    NSMutableDictionary *params = [[self.delegate commonTrackParams] mutableCopy];
    if (extra) {
        [params addEntriesFromDictionary:extra];
    }
    [ACCTracker() track:event params:[params copy]];
}

#pragma mark - Getter
- (ACCNewYearWishEditModel *)wishModel
{
    return self.publishModel.repoActivity.wishModel;
}

@end
