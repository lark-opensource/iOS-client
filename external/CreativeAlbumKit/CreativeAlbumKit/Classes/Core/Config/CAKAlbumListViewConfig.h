//
//  CAKAlbumListViewConfig.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2020/12/15.
//

#import <Foundation/Foundation.h>
#import "CAKAlbumListTabConfig.h"
#import "CAKPhotoManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CAKAlbumAssetsSelectedIconStyle) {
    CAKAlbumAssetsSelectedIconStyleNumber,        // number
    CAKAlbumAssetsSelectedIconStyleCheckMark,        // check mark
};

typedef NS_ENUM(NSUInteger, CAKAlbumAssetsOrder) {
    CAKAlbumAssetsOrderAscending,
    CAKAlbumAssetsOrderDescending,
};

typedef NS_ENUM(NSInteger, CAKAlbumEventSourceType) {
    CAKAlbumEventSourceTypeAlbumPage,
    CAKAlbumEventSourceTypePreviewPage,
};

typedef NS_ENUM(NSUInteger, CAKAlbumSelectionLimitType) {
    CAKAlbumSelectionLimitTypeTotal,
    CAKAlbumSelectionLimitTypeSeparate,
};

@class CAKAlbumAssetModel;

FOUNDATION_EXTERN NSString * const CAKAlbumTabIdentifierAll;
FOUNDATION_EXTERN NSString * const CAKAlbumTabIdentifierImage;
FOUNDATION_EXTERN NSString * const CAKAlbumTabIdentifierVideo;

@interface CAKAlbumListViewConfig : NSObject

@property (nonatomic, strong) CAKAlbumListTabConfig *mixedAssetsTabConfig;
@property (nonatomic, strong) CAKAlbumListTabConfig *photoAssetsTabConfig;
@property (nonatomic, strong) CAKAlbumListTabConfig *videoAssetsTabConfig;

@property (nonatomic, assign) BOOL enableTabView;

@property (nonatomic, assign) BOOL enableAssetsRepeatedSelect;
@property (nonatomic, assign) BOOL addAssetInOrder;
@property (nonatomic, assign) BOOL enableMixedUpload;
@property (nonatomic, assign) CAKAlbumAssetSortStyle assetsSortStyle;
@property (nonatomic, assign) BOOL enableiOS14AlbumAuthorizationGuide;
@property (nonatomic, assign) BOOL shouldShowiOS14GoSettingStrip;
@property (nonatomic, assign) BOOL enableAlbumAuthorizationDenyAccessGuide;

@property (nonatomic, assign) CGFloat horizontalInset;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, assign) CAKAlbumAssetsSelectedIconStyle assetsSelectedIconStyle;
@property (nonatomic, assign) CAKAlbumAssetsOrder assetsOrder;


@property (nonatomic, assign) CAKAlbumSelectionLimitType selectionLimitType;
@property (nonatomic, assign) BOOL withoutCountLimitation;
@property (nonatomic, assign) NSInteger maxAssetsSelectionCount;
@property (nonatomic, assign) NSInteger minAssetsSelectionCount;
@property (nonatomic, assign) NSInteger maxVideoAssetsSelectionCount;
@property (nonatomic, assign) NSInteger minVideoAssetsSelectionCount;
@property (nonatomic, assign) NSInteger maxPhotoAssetsSelectionCount;
@property (nonatomic, assign) NSInteger minPhotoAssetsSelectionCount;

@property (nonatomic, assign) CGSize aspectRatio;
@property (nonatomic, assign) NSString *defaultTabIdentifier;

@property (nonatomic, assign) BOOL scrollToBottom;

@property (nonatomic, assign) CGFloat videoSelectableMinSeconds;
@property (nonatomic, assign) CGFloat videoSelectableMaxSeconds;

@property (nonatomic, copy) NSArray<CAKAlbumAssetModel *> *initialSelectedAssetModelArray;
@property (nonatomic, copy) NSSet<NSString *> *showCornerTagAssetLocalIdentifierSet;
@property (nonatomic, assign) BOOL shouldShowCornerTagView;
@property (nonatomic, assign) BOOL enableDisplayFavoriteSymbol;
@property (nonatomic, copy) NSString *cornerTagContext;
@property (nonatomic, assign) BOOL enableSyncInitialSelectedAssets;
@property (nonatomic, assign) BOOL enableHorizontalAssetBlackEdge;
@property (nonatomic, assign) BOOL shouldDismissPreviewPageWhenNext;
@property (nonatomic, assign) BOOL previewNextNeverDisabled;

@property (nonatomic, assign) BOOL enableBlackStyle;
@property (nonatomic, assign) BOOL enableMultithreadOpt;

@end

NS_ASSUME_NONNULL_END
