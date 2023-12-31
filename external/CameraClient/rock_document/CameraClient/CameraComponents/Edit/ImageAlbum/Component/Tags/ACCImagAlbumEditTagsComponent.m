//
//  ACCImagAlbumEditTagsComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCImagAlbumEditTagsComponent.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCBarItem+Adapter.h"
#import "ACCEditTagsPickerViewController.h"
#import "ACCEditImageAlbumMixedProtocolD.h"
#import "ACCImageAlbumEditTagStickerHandler.h"
#import "AWERepoStickerModel.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCEditTagStickerView.h"
#import "ACCConfigKeyDefines.h"
#import "ACCImageAlbumData.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWERepoTrackModel.h"

@interface ACCImagAlbumEditTagsComponent ()<ACCPanelViewDelegate, ACCEditTagsPickerViewControllerDelegate, ACCEditTagDataProvider>

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) id<ACCStickerServiceProtocol> stickerService;

@property (nonatomic, strong) ACCEditTagsPickerViewController *tagsPickerViewController;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) ACCImageAlbumEditTagStickerHandler *tagHandler;

@end

@implementation ACCImagAlbumEditTagsComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

- (void)componentDidMount
{
    if (!self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        NSAssert(NO, @"should not added for video edit mode");
        return;
    }
    [self.viewContainer.panelViewController registerObserver:self];
    [self.viewContainer addToolBarBarItem:[self tagBarItem]];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.tagHandler = [[ACCImageAlbumEditTagStickerHandler alloc] init];
    @weakify(self);
    self.tagHandler.onEditTag = ^(ACCEditTagStickerView *tagView) {
        @strongify(self);
        [self showPanelWithSelectedTag:tagView.interactionStickerModel];
    };
    self.tagHandler.dataProvider = self;
    self.tagHandler.onTagChangeDirection = ^(ACCEditTagStickerView *tagView) {
        @strongify(self);
        [self.tagHandler reverseTag:tagView];
    };
    [self.stickerService registStickerHandler:self.tagHandler];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - Private Helper

- (ACCBarItem<ACCEditBarItemExtraData*>*)tagBarItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarTagsContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.location = config.location;
    barItem.itemId = ACCEditToolBarTagsContext;
    barItem.type = ACCBarItemFunctionTypeCover;
    
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        NSMutableDictionary *params = [[self.repository.repoTrack referExtra] mutableCopy];
        [params addEntriesFromDictionary:[self.repository.repoTrack mediaCountInfo]?:@{}];
        params[@"pic_location"] = @([self.editService.imageAlbumMixed currentImageEditorIndex] + 1);
        [ACCTracker() trackEvent:@"click_photo_tag_entrance" params:params];
        [self tagsButtonClicked];
    };
    barItem.needShowBlock = ^BOOL{
        return YES;
    };
    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeTags];
    return barItem;
}

- (NSUInteger)totalTagCount
{
    __block NSUInteger totalCount = 0;
    [self.repository.repoImageAlbumInfo.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([ACCImageAlbumMixedD(self.editService.imageAlbumMixed) currentImageEditorIndex] != idx) {
            [obj.stickerInfo.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.type == AWEInteractionStickerTypeEditTag) {
                    totalCount++;
                }
            }];
        } else {
            totalCount += [self.tagHandler numberOfTags];
        }
    }];
    return totalCount;
}

#pragma mark - Event Handling

- (void)tagsButtonClicked
{
    NSInteger maxNumberOfTags = ACCConfigInt(kConfigBool_editor_tags_max_count_per_image);
    NSInteger maxNumberOfTotalTags = ACCConfigInt(kConfigBool_editor_tags_max_count_total);
    if ([self.tagHandler numberOfTags] >= maxNumberOfTags) {
        [ACCToast() showToast:[NSString stringWithFormat:@"每张图片最多添加%@个标记", @(maxNumberOfTags)]];
        return;
    }
    if ([self totalTagCount] >= maxNumberOfTotalTags) {
        [ACCToast() showToast:[NSString stringWithFormat:@"每个作品最多添加%@个标记", @(maxNumberOfTotalTags)]];
        return;
    }
    [self showPanelWithSelectedTag:nil];
}

- (void)dismissPanel
{
    [self.viewContainer.panelViewController dismissPanelView:self.tagsPickerViewController duration:[self.tagsPickerViewController animationDuration]];
}

- (void)showPanelWithSelectedTag:(AWEInteractionEditTagStickerModel *)tag
{
    self.tagsPickerViewController.originalTag = tag;
    self.tagsPickerViewController.baseTrackerParams = [self baseTrackerParams];
    [self.tagsPickerViewController resetPanel];
    [self.viewContainer.panelViewController showPanelView:self.tagsPickerViewController duration:[self.tagsPickerViewController animationDuration]];
}

- (void)tagsPicker:(ACCEditTagsPickerViewController *)tagsPicker didPanWithRatio:(CGFloat)ratio finished:(BOOL)finished dismiss:(BOOL)dismiss
{
    if (finished) {
        if (!dismiss) {
            [UIView animateWithDuration:[tagsPicker animationDuration] / 2 * ratio animations:^{
                self.viewContainer.containerView.alpha = .0f;
            }];
        } else {
            [UIView animateWithDuration:[tagsPicker animationDuration] / 2 * (1 - ratio) animations:^{
                self.viewContainer.containerView.alpha = 1.f;
            } completion:^(BOOL finished) {
                [self.viewContainer.panelViewController dismissPanelView:self.tagsPickerViewController];
            }];
        }
    } else {
        self.viewContainer.containerView.alpha = ratio;
    }
}

- (void)tagsPickerDidTapTopBar:(ACCEditTagsPickerViewController *)tagsPicker
{
    [self dismissPanel];
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCEditTagsPickerContext) {
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"tagsPanel"];
        [UIView animateWithDuration:[self.tagsPickerViewController animationDuration] animations:^{
            self.viewContainer.containerView.alpha = .0f;
        }];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCEditTagsPickerContext) {
        [self.viewContainer.rootView insertSubview:self.maskView aboveSubview:self.viewContainer.containerView];
        ACCMasMaker(self.maskView, {
            make.edges.equalTo(self.viewContainer.rootView);
        });
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCEditTagsPickerContext) {
        [UIView animateWithDuration:[self.tagsPickerViewController animationDuration] animations:^{
            self.viewContainer.containerView.alpha = 1.0;
        }];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCEditTagsPickerContext) {
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"tagsPanel"];
        [self.maskView removeFromSuperview];
    }
}

#pragma mark - ACCEditTagsPickerViewControllerDelegate

- (void)tagsPicker:(ACCEditTagsPickerViewController *)tagsPicker didSelectTag:(AWEInteractionEditTagStickerModel *)tag originalTag:(AWEInteractionEditTagStickerModel *)originalTag
{
    if (originalTag != nil) {
        ACCStickerViewType sticker = [[self.stickerService.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdEditTag] acc_match:^BOOL(ACCStickerViewType  _Nonnull item) {
            if ([item.contentView isKindOfClass:[ACCEditTagStickerView class]]) {
                ACCEditTagStickerView *view = (ACCEditTagStickerView *)item.contentView;
                return view.interactionStickerModel == originalTag;
            }
            return NO;
        }];
        ACCEditTagStickerView *tagView = (ACCEditTagStickerView *)sticker.contentView;
        if (tagView != nil) {
            tag.editTagInfo.orientation = originalTag.editTagInfo.orientation;
            [tagView updateInteractionModel:tag];
            [self.tagHandler makeGeometrySafeWithTag:tagView withNewCenter:sticker.center];
        } else {
            [self.tagHandler addTagWithModel:tag inContainerView:self.tagHandler.stickerContainerView
                            constructorBlock:^(ACCAlbumEditTagStickerConfig * _Nullable config) {
                
            }];
        }
    } else {
        [self.tagHandler addTagWithModel:tag inContainerView:self.tagHandler.stickerContainerView
                        constructorBlock:^(ACCAlbumEditTagStickerConfig * _Nullable config) {
            
        }];
    }
    [self dismissPanel];
}

#pragma mark - ACCEditTagDataProvider

- (NSInteger)picLocation
{
    return [self.editService.imageAlbumMixed currentImageEditorIndex];
}

#pragma mark - Getters

- (ACCEditTagsPickerViewController *)tagsPickerViewController
{
    if (!_tagsPickerViewController) {
        _tagsPickerViewController = [[ACCEditTagsPickerViewController alloc] init];
        _tagsPickerViewController.delegate = self;
    }
    return _tagsPickerViewController;
}

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPanel)];
        [_maskView addGestureRecognizer:tap];
    }
    return _maskView;
}

- (NSDictionary *)baseTrackerParams
{
    NSDictionary *commonParams = [self.repository.repoTrack referExtra];
    NSInteger picCount = [self.repository.repoTrack.mediaCountInfo[@"pic_cnt"] integerValue];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:commonParams[@"shoot_way"] forKey:@"shoot_way"];
    [params setValue:commonParams[@"creation_id"] forKey:@"creation_id"];
    [params setValue:commonParams[@"content_type"] forKey:@"content_type"];
    [params setValue:commonParams[@"content_source"] forKey:@"content_source"];
    [params setValue:picCount > 1 ? @(YES) : @(NO)  forKey:@"is_multi_content"];
    [params setValue:@(picCount) forKey:@"pic_cnt"];
    [params setValue:@([self.editService.imageAlbumMixed currentImageEditorIndex] + 1) forKey:@"pic_location"];
    return [params copy];
}

@end
