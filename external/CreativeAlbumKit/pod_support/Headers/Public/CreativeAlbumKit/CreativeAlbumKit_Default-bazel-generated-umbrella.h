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

#import "CAKAlbumAssetListCell.h"
#import "CAKAlbumBottomViewConfig.h"
#import "CAKAlbumCategorylistCell.h"
#import "CAKAlbumDenyAccessView.h"
#import "CAKAlbumGoSettingStrip.h"
#import "CAKAlbumListBlankView.h"
#import "CAKAlbumListViewController.h"
#import "CAKAlbumNavigationViewConfig.h"
#import "CAKAlbumNavigationViewProtocol.h"
#import "CAKAlbumPhotoPreviewAndSelectCell.h"
#import "CAKAlbumPreviewAndSelectCell.h"
#import "CAKAlbumPreviewAndSelectController.h"
#import "CAKAlbumPreviewPageBottomView.h"
#import "CAKAlbumPreviewPageBottomViewProtocol.h"
#import "CAKAlbumRequestAccessView.h"
#import "CAKAlbumRequestAccessViewProtocol.h"
#import "CAKAlbumSelectAlbumButton.h"
#import "CAKAlbumSelectedAssetsView.h"
#import "CAKAlbumSelectedAssetsViewConfig.h"
#import "CAKAlbumSlidingScrollView.h"
#import "CAKAlbumSlidingTabBarView.h"
#import "CAKAlbumSlidingViewController.h"
#import "CAKAlbumSwitchBottomView.h"
#import "CAKAlbumVideoPreviewAndSelectCell.h"
#import "CAKAlbumViewController.h"
#import "CAKAlbumViewControllerNavigationView.h"
#import "CAKAlbumViewModel.h"
#import "CAKAnimatedButton.h"
#import "CAKBaseServiceContainer.h"
#import "CAKBounceDismissAnimationController.h"
#import "CAKBouncePresentAnimationController.h"
#import "CAKCircularProgressView.h"
#import "CAKCornerBarNavigationController.h"
#import "CAKGradientView.h"
#import "CAKLanguageManager.h"
#import "CAKLoadingProtocol.h"
#import "CAKModalTransitionDelegate.h"
#import "CAKReorderableForCollectionViewFlowLayout.h"
#import "CAKResourceBundleProtocol.h"
#import "CAKResourceUnion.h"
#import "CAKServiceLocator.h"
#import "CAKStatusBarControllerUtil.h"
#import "CAKSwipeInteractionController.h"
#import "CAKToastProtocol.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+AlbumKit.h"
#import "UIImage+CAKUIKit.h"

FOUNDATION_EXPORT double CreativeAlbumKitVersionNumber;
FOUNDATION_EXPORT const unsigned char CreativeAlbumKitVersionString[];