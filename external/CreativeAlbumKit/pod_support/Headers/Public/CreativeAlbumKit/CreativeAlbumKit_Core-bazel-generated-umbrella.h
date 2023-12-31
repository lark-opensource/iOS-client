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

#import "CAKAlbumAssetCache.h"
#import "CAKAlbumAssetModel+Cover.h"
#import "CAKAlbumAssetModel.h"
#import "CAKAlbumBaseViewModel.h"
#import "CAKAlbumBottomViewProtocol.h"
#import "CAKAlbumDataModel.h"
#import "CAKAlbumListTabConfig.h"
#import "CAKAlbumListViewConfig.h"
#import "CAKAlbumListViewControllerProtocol.h"
#import "CAKAlbumSectionModel.h"
#import "CAKAlbumTransitionAnimationController.h"
#import "CAKAlbumTransitionContextProvider.h"
#import "CAKAlbumTransitionDelegateProtocol.h"
#import "CAKAlbumTransitionInteractionController.h"
#import "CAKAlbumZoomTransition.h"
#import "CAKAlbumZoomTransitionDelegate.h"
#import "CAKPhotoManager.h"
#import "CAKSelectedAssetsViewProtocol.h"

FOUNDATION_EXPORT double CreativeAlbumKitVersionNumber;
FOUNDATION_EXPORT const unsigned char CreativeAlbumKitVersionString[];