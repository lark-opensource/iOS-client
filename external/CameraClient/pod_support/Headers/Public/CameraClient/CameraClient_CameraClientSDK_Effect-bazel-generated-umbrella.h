#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AWEAutoresizingCollectionView.h"
#import "AWECollectionStickerPickerController.h"
#import "AWECollectionStickerPickerModel.h"
#import "AWEDouyinStickerCategoryModel.h"
#import "AWEExploreStickerViewController.h"
#import "AWEPhotoPickerCollectionViewCell.h"
#import "AWEPhotoPickerController.h"
#import "AWEPhotoPickerModel.h"
#import "AWEStickerCategoryModel.h"
#import "AWEStickerDownloadManager.h"
#import "AWEStickerPicckerDataSource.h"
#import "AWEStickerPickerCategoryBaseCell.h"
#import "AWEStickerPickerCategoryCell.h"
#import "AWEStickerPickerCategoryTabView.h"
#import "AWEStickerPickerCollectionViewCell.h"
#import "AWEStickerPickerController+LayoutManager.h"
#import "AWEStickerPickerController.h"
#import "AWEStickerPickerControllerPluginProtocol.h"
#import "AWEStickerPickerDataContainer.h"
#import "AWEStickerPickerDataContainerProtocol.h"
#import "AWEStickerPickerDefaultLogger.h"
#import "AWEStickerPickerDefaultUIConfiguration.h"
#import "AWEStickerPickerEmptyView.h"
#import "AWEStickerPickerErrorView.h"
#import "AWEStickerPickerExploreView.h"
#import "AWEStickerPickerFavoriteView.h"
#import "AWEStickerPickerHashtagCollectionViewCell.h"
#import "AWEStickerPickerHashtagView.h"
#import "AWEStickerPickerLoadingView.h"
#import "AWEStickerPickerLogMarcos.h"
#import "AWEStickerPickerLogger.h"
#import "AWEStickerPickerModel+Favorite.h"
#import "AWEStickerPickerModel+Search.h"
#import "AWEStickerPickerModel.h"
#import "AWEStickerPickerOverlayView.h"
#import "AWEStickerPickerSearchBar.h"
#import "AWEStickerPickerSearchBarConfig.h"
#import "AWEStickerPickerSearchCollectionViewCell.h"
#import "AWEStickerPickerSearchView.h"
#import "AWEStickerPickerStickerBaseCell.h"
#import "AWEStickerPickerStickerCell.h"
#import "AWEStickerPickerTabViewLayout.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"
#import "AWEStickerPickerView.h"
#import "AWEStickerViewLayoutManagerProtocol.h"

FOUNDATION_EXPORT double CameraClientVersionNumber;
FOUNDATION_EXPORT const unsigned char CameraClientVersionString[];