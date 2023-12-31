//
//  ACCImageEditHDRComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/8.
//

#import "ACCImageEditHDRComponent.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCEditorDraftService.h"
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "NSObject+ACCEventContext.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumData.h"
#import "AWEImageEditHDRModelManager.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCBarItem+Adapter.h"

@interface ACCImageEditHDRComponent ()

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, assign) BOOL isLensHDREvnEnable;

@end

@implementation ACCImageEditHDRComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

#pragma mark - life cycle
- (void)componentDidMount {
    
    if (![self repository].repoImageAlbumInfo.isImageAlbumEdit) {
        NSAssert(NO, @"should not added for image edit mode");
        return;
    }
    self.isLensHDREvnEnable = [AWEImageEditHDRModelManager enableImageLensHDR];
    // 直接进编辑页，下载算法
    [AWEImageEditHDRModelManager downloaImageLensHDRResourceIfNeeded];
    
    if (self.isLensHDREvnEnable) {
        [self.viewContainer addToolBarBarItem:[self p_barItem]];
        [self.editService.imageEditHDR setupLensHDRModelWithFilePath:[AWEImageEditHDRModelManager lensHDRFilePath]];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentWillAppear
{
    if (self.isLensHDREvnEnable) {
        [self p_updateHDRBarItemStatus];
    }
}

#pragma mark - private
- (void)p_onHDRBarButtonClicked:(UIButton *)button
{
    BOOL enable = button.selected;

    [self p_setHDRNetEnabled:enable];
    [self p_trackHDRNet:enable];
    
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    [draftService hadBeenModified];
}

- (void)p_setHDRNetEnabled:(BOOL)enabled
{
    [self.editService.imageEditHDR setHDREnable:enabled];
    [ACCAPM() attachFilter:@(enabled) forKey:@"hdr_enabled"];
}

- (void)p_updateHDRBarItemStatus
{
    if (![AWEImageEditHDRModelManager enableImageLensHDR]) {
        return;
    }
    
    BOOL enableHDRNet = [self editService].imageAlbumMixed.currentImageItemModel.HDRInfo.enableHDRNet;

    if (enableHDRNet) {
        [self p_videoEnhanceButton].selected = YES;
    }
}

- (void)p_trackHDRNet:(BOOL)enable
{
    NSDictionary *referExtra = self.repository.repoTrack.referExtra;

    [self.containerViewController acc_trackEvent:@"click_quality_improve" attributes:^(ACCAttributeBuilder *build) {
        build.enterFrom.equalTo(@"video_edit_page");
        build.attribute(@"to_status").equalTo(enable ? @"on" : @"off");
        build.attribute(@"creation_id").equalTo(self.repository.repoContext.createId);
        build.attribute(@"content_type").equalTo(referExtra[@"content_type"]);
        build.attribute(@"shoot_way").equalTo(referExtra[@"shoot_way"]);
        build.attribute(@"content_source").equalTo(referExtra[@"content_source"]);
        build.attribute(@"improve_method").equalTo(@"hdr");
        build.attribute(@"is_multi_content").equalTo(self.repository.repoTrack.mediaCountInfo[@"is_multi_content"]);
    }];
}

#pragma mark - getter
- (UIViewController *)containerViewController
{
    if ([self.controller isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.controller;
    }
    NSAssert(nil, @"exception");
    return nil;
}

- (UIButton *)p_videoEnhanceButton
{
    UIButton *ret = [self.viewContainer viewWithBarItemID:ACCEditToolBarVideoEnhanceContext].button;
    return ret;
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)p_barItem
{
    
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarVideoEnhanceContext];
    if (!config) return nil;

    ACCBarItem<ACCEditBarItemExtraData*>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.selectedImageName = config.selectedImageName;
    bar.itemId = ACCEditToolBarVideoEnhanceContext;
    bar.type = ACCBarItemFunctionTypeDefault;
    NSString *title = [config.title copy];
    
    @weakify(self);

    bar.barItemViewConfigBlock = ^(UIView * _Nonnull itemView) {
        UIButton *barItemButton;
        if ([itemView isKindOfClass:[AWEEditActionItemView class]]) {
            AWEEditActionItemView *editItemView = (AWEEditActionItemView*)itemView;
            barItemButton = editItemView.button;
        } else if ([itemView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)itemView;
            barItemButton = button;
        }
        if (barItemButton) {
            barItemButton.isAccessibilityElement = YES;
            barItemButton.accessibilityTraits = UIAccessibilityTraitButton;
            barItemButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", title, barItemButton.selected ? @"已开启" : @"已关闭"];
            barItemButton.adjustsImageWhenHighlighted = NO;
        }
    };
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        UIButton *barItemButton;
        if ([itemView isKindOfClass:[AWEEditActionItemView class]]) {
            AWEEditActionItemView *editItemView = (AWEEditActionItemView*)itemView;
            editItemView.button.selected = !editItemView.button.selected;
            barItemButton = editItemView.button;
            [self p_onHDRBarButtonClicked:editItemView.button];
        } else if ([itemView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)itemView;
            button.selected = !button.selected;
            barItemButton = button;
            [self p_onHDRBarButtonClicked:button];
        }
        if (barItemButton) {
            barItemButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", title, barItemButton.selected ? @"已开启" : @"已关闭"];
        }
    };
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeVideoEnhance];
    return bar;
}

#pragma mark - Draft recover
+ (NSArray <NSString *> *)modelsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    if (!ACCConfigBool(kConfigBool_enable_images_album_publish) || [AWEImageEditHDRModelManager didLensHDRResourcesDownloaded]) {
        return @[];
    }
    
    NSArray <NSString *> *models = [AWEImageEditHDRModelManager lensHDRModelNames];
    return [models copy];
}

+ (NSArray <NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    return @[];
}


@end
