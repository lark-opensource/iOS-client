//
//  CAKAlbumListViewConfig.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2020/12/15.
//

#import "CAKAlbumListViewConfig.h"
#import <Photos/PHPhotoLibrary.h>

const NSInteger MaxSelectionAssetCount = 35;
NSString * const CAKAlbumTabIdentifierAll = @"all";
NSString * const CAKAlbumTabIdentifierImage = @"image";
NSString * const CAKAlbumTabIdentifierVideo = @"video";

@implementation CAKAlbumListViewConfig

- (instancetype)init
{
    if (self = [super init]) {
        _enableMixedUpload = YES;
        _enableTabView = YES;
        _enableAssetsRepeatedSelect = NO;
        _addAssetInOrder = NO;
        _enableiOS14AlbumAuthorizationGuide = YES;
        _horizontalInset = 0.0;
        _columnNumber = 4;
        _assetsSelectedIconStyle = CAKAlbumAssetsSelectedIconStyleNumber;
        _assetsSortStyle = 0;
        _assetsOrder = CAKAlbumAssetsOrderAscending;
        _maxAssetsSelectionCount = MaxSelectionAssetCount;
        _minAssetsSelectionCount = 1;
        _aspectRatio = CGSizeZero;
        _defaultTabIdentifier = CAKAlbumTabIdentifierAll;
        _scrollToBottom = YES;
        _videoSelectableMaxSeconds = 3600;
        _videoSelectableMinSeconds = 1;
        _enableSyncInitialSelectedAssets = YES;
        _enableHorizontalAssetBlackEdge = NO;
        _mixedAssetsTabConfig = [[CAKAlbumListTabConfig alloc] init];
        _photoAssetsTabConfig = [[CAKAlbumListTabConfig alloc] init];
        _videoAssetsTabConfig = [[CAKAlbumListTabConfig alloc] init];
        _shouldDismissPreviewPageWhenNext = NO;
        _enableBlackStyle = NO;
        _shouldShowCornerTagView = NO;
        _withoutCountLimitation = NO;
        _enableDisplayFavoriteSymbol = NO;
    }
    return self;
}

- (void)setEnableiOS14AlbumAuthorizationGuide:(BOOL)enableiOS14AlbumAuthorizationGuide
{
    _enableiOS14AlbumAuthorizationGuide = enableiOS14AlbumAuthorizationGuide;
    if (enableiOS14AlbumAuthorizationGuide) {
#ifdef __IPHONE_14_0 //xcode12
        if (@available(iOS 14.0, *)) {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
            if (status == PHAuthorizationStatusLimited) {
                _shouldShowiOS14GoSettingStrip = YES;
            }
        }
#endif
    }
}

@end
