//
//  CAKAlbumViewModel.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/17.
//

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <Photos/PHPhotoLibrary.h>
#import "CAKAlbumListViewController.h"
#import "CAKAlbumPreviewAndSelectController.h"
#import "CAKLanguageManager.h"

@interface CAKAlbumViewModel()

@property (nonatomic, strong) NSMutableArray<NSNumber *> *currentNilIndexArray;

@end

@implementation CAKAlbumViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _navigationViewConfig = [[CAKAlbumNavigationViewConfig alloc] init];
        _bottomViewConfig = [[CAKAlbumBottomViewConfig alloc] init];
        _selectedAssetsViewConfig = [[CAKAlbumSelectedAssetsViewConfig alloc] init];
    }
    
    return self;
}

#pragma mark - init
- (UIViewController<CAKAlbumListViewControllerProtocol> *)albumListVCWithResourceType:(AWEGetResourceType)type
{
    CAKAlbumListViewController *listVC = [[CAKAlbumListViewController alloc] initWithResourceType:type];
    listVC.viewModel = self;
    listVC.resourceType = type;
    listVC.enableBottomViewShow = YES;
    listVC.enableSelectedAssetsViewShow = YES;
    
    switch (type) {
        case AWEGetResourceTypeImage:
        {
            listVC.title = CAKLocalizedString(@"album_image", @"Image");
            listVC.tabIdentifier = CAKAlbumTabIdentifierImage;
            listVC.tabConfig = self.listViewConfig.photoAssetsTabConfig;
            break;
        }
            
        case AWEGetResourceTypeVideo:
        {
            listVC.title = CAKLocalizedString(@"album_video", @"Video");
            listVC.tabIdentifier = CAKAlbumTabIdentifierVideo;
            listVC.tabConfig = self.listViewConfig.videoAssetsTabConfig;
            break;
        }
        case AWEGetResourceTypeImageAndVideo:
        {
            listVC.title = CAKLocalizedString(@"shoot_album_all", @"all");
            listVC.tabIdentifier = CAKAlbumTabIdentifierAll;
            listVC.tabConfig = self.listViewConfig.mixedAssetsTabConfig;
            break;
        }
            
        default:
            break;
    }

    return listVC;
}

- (CAKAlbumListBlankViewType)blankViewTypeWithResourceType:(AWEGetResourceType)type
{
    if (type == AWEGetResourceTypeImage) {
        return CAKAlbumListBlankViewTypeNoPhoto;
    } else if (type == AWEGetResourceTypeVideo) {
        return CAKAlbumListBlankViewTypeNoVideo;
    } else {
        return CAKAlbumListBlankViewTypeNoVideoAndPhoto;
    }
}

- (void)updateNilIndexArray:(NSMutableArray<NSNumber *> *)nilIndexArray
{
    self.currentNilIndexArray = nilIndexArray.mutableCopy;
}

- (CAKAlbumPreviewAndMultiSelectType)previewAndMultiSelectTypeWithListViewController:(CAKAlbumListViewController *)listViewController
{
    if (listViewController.tabConfig.enablePreview && listViewController.tabConfig.enableMultiSelect) {
        return CAKAlbumPreviewAndMultiSelectTypeBothEnabled;
    }
    if (!listViewController.tabConfig.enablePreview && !listViewController.tabConfig.enableMultiSelect) {
        return CAKAlbumPreviewAndMultiSelectTypeBothDisabled;
    }
    if (!listViewController.tabConfig.enablePreview && listViewController.tabConfig.enableMultiSelect) {
        return CAKAlbumPreviewAndMultiSelectTypeEnableMultiSelectDisablePreview;
    }
    return CAKAlbumPreviewAndMultiSelectTypeEnablePreviewDisableMultiSelect;
}

@end
