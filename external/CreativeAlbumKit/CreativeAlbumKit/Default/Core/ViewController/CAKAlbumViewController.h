//
//  CAKAlbumViewController.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/16.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumListViewControllerProtocol.h"

#import "CAKAlbumViewControllerNavigationView.h"
#import "CAKSwipeInteractionController.h"
#import "CAKAlbumNavigationViewConfig.h"
#import "CAKAlbumListViewConfig.h"
#import "CAKAlbumBottomViewConfig.h"
#import "CAKAlbumSelectedAssetsViewConfig.h"
#import "CAKAlbumBottomViewProtocol.h"
#import "CAKAlbumPreviewPageBottomViewProtocol.h"
#import "CAKSelectedAssetsViewProtocol.h"
#import "CAKAlbumRequestAccessViewProtocol.h"
#import "CAKAlbumAssetModel.h"
#import "CAKAlbumPreviewPageBottomView.h"

FOUNDATION_EXTERN NSString * const CAKAlbumTabIdentifierAll;
FOUNDATION_EXTERN NSString * const CAKAlbumTabIdentifierImage;
FOUNDATION_EXTERN NSString * const CAKAlbumTabIdentifierVideo;

@class CAKAlbumViewController;

@protocol CAKAlbumViewControllerDataSource <NSObject>

@optional

- (BOOL)albumViewControllerHiddenForHeader:(CAKAlbumViewController * _Nullable)album;
- (BOOL)albumViewControllerHiddenForFooter:(CAKAlbumViewController * _Nullable)album;
- (BOOL)albumViewControllerHiddenForSelectedAssetsView:(CAKAlbumViewController * _Nullable)album;

- (CGFloat)albumViewControllerHeightForHeader:(CAKAlbumViewController * _Nullable)album;
- (CGFloat)albumViewControllerHeightForFooter:(CAKAlbumViewController * _Nullable)album;
- (CGFloat)albumViewControllerHeightForSelectedAssetsView:(CAKAlbumViewController * _Nullable)album;
- (CGFloat)albumViewControllerHeightForPreviewFooter:(CAKAlbumViewController * _Nullable)album;

- (CAKAlbumNavigationViewConfig * _Nullable)albumViewControllerConfigForHeader:(CAKAlbumViewController * _Nullable)album;
- (CAKAlbumListViewConfig * _Nullable)listViewConfigForAlbumViewController:(CAKAlbumViewController * _Nullable)album;
- (CAKAlbumBottomViewConfig * _Nullable)albumViewControllerConfigForFooter:(CAKAlbumViewController * _Nullable)album;
- (CAKAlbumSelectedAssetsViewConfig * _Nullable)albumViewControllerConfigForSelectedAssetsView:(CAKAlbumViewController * _Nullable)album;

- (nonnull UIView<CAKAlbumNavigationViewProtocol> *)albumViewControllerViewForHeader:(CAKAlbumViewController * _Nullable)album;
- (nonnull UIView<CAKAlbumBottomViewProtocol> *)albumViewControllerViewForFooter:(CAKAlbumViewController * _Nullable)album;

- (UIView<CAKSelectedAssetsViewProtocol> * _Nullable)albumViewControllerViewForSelectedAssets:(CAKAlbumViewController * _Nullable)album;
- (UIView<CAKSelectedAssetsViewProtocol> * _Nullable)albumViewControllerViewForSelectedAssetsInPreviewPage:(CAKAlbumViewController * _Nullable)album;

- (UIView<CAKAlbumRequestAccessViewProtocol> * _Nullable)albumViewControllerViewForiOS14RequestAccessView:(CAKAlbumViewController * _Nullable)album;
- (UIView<CAKAlbumRequestAccessViewProtocol> * _Nullable)albumViewControllerViewForiOS14DenyAccessView:(CAKAlbumViewController * _Nullable)album;


- (NSArray<UIViewController<CAKAlbumListViewControllerProtocol> *> * _Nullable)albumListViewControllersDataSource:(CAKAlbumViewController * _Nullable)album;

- (BOOL)albumViewControllerNeedFetchAlbumAssetsWhenClickNext:(CAKAlbumViewController * _Nullable)album;//optimize performance

- (BOOL)albumViewControllerShouldShowBottomViewForPreviewPage:(CAKAlbumViewController * _Nullable)album;
- (UIView<CAKAlbumPreviewPageBottomViewProtocol> * _Nullable)albumViewControllerViewForBottomInPreviewPage:(CAKAlbumViewController * _Nullable)album;

@end

@protocol CAKAlbumViewControllerDelegate <NSObject>

@optional

- (void)albumViewControllerDidLoad:(CAKAlbumViewController * _Nullable)album;

- (void)albumViewControllerDidAppear:(CAKAlbumViewController * _Nullable)album;

- (void)albumListViewControllerDidLoad:(UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable)listViewController;

- (void)albumListViewControllerWillAppear:(UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable)listViewController;

- (void)albumListViewControllerWillDisappear:(UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable)listViewController;

- (void)albumViewControllerDealloc:(CAKAlbumViewController * _Nullable)album;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album selectedAssetsViewDidDeleteAsset:(CAKAlbumAssetModel * _Nullable)albumAsset sourceType:(CAKAlbumEventSourceType)sourceType;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album selectedAssetsViewDidClickAsset:(CAKAlbumAssetModel * _Nullable)albumAsset sourceType:(CAKAlbumEventSourceType)sourceType;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album selectedAssetsViewDidChangeOrderWithAsset:(CAKAlbumAssetModel * _Nullable)albumAsset sourceType:(CAKAlbumEventSourceType)sourceType;

- (BOOL)albumViewController:(CAKAlbumViewController * _Nullable)album shouldSelectAlbumAsset:(CAKAlbumAssetModel * _Nullable)albumAsset;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didSelectAlbumAsset:(CAKAlbumAssetModel * _Nullable)albumAsset sourceType:(CAKAlbumEventSourceType)sourceType;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didDeselectAlbumAsset:(CAKAlbumAssetModel * _Nullable)albumAsset sourceType:(CAKAlbumEventSourceType)sourceType;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didShowAlbumAssetCell:(CAKAlbumAssetModel * _Nullable)albumAsset listViewController:(UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable)listViewController;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didClickAlbumAssetCell:(CAKAlbumAssetModel * _Nullable)albumAsset;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didSwitchMultiSelect:(BOOL)isMultiSelect;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album previewControllerDidLoadForAlbumAsset:(CAKAlbumAssetModel * _Nullable)albumAsset bottomView:(CAKAlbumPreviewPageBottomView * _Nullable)bottomView;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:(CAKAlbumAssetModel * _Nullable)albumAsset;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album previewControllerWillBeginSetupPlayer:(AVPlayer * _Nullable)player status:(NSInteger)status;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album previewControllerDidEndZoomingWithIsZoomIn:(BOOL)isZoomIn albumAsset:(CAKAlbumAssetModel * _Nullable)albumAsset;

- (void)albumViewControllerEndPreview:(CAKAlbumViewController * _Nullable)album;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didClickNextButtonWithSourceType:(CAKAlbumEventSourceType)sourceType fetchedAlbumAssets:(NSArray<CAKAlbumAssetModel *> * _Nullable)fetchedAlbumAssets;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didFinishFetchICloudWithDuration:(NSTimeInterval)duration size:(NSInteger)size;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didDismissWithPanProgress:(CGFloat)panProgress;

- (void)albumViewControllerDidClickCancelButton:(CAKAlbumViewController * _Nullable)album;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didSelectTabListViewController:(UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable)listViewController index:(NSInteger)index;

//update timing:select asset, deselect asset, delete asset on bottom view, delete asset on preview page
- (void)albumViewController:(CAKAlbumViewController * _Nullable)album updateBottomNextButtonWithButton:(UIButton * _Nullable)button fromPreview:(BOOL)fromPreview;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didSelectAlbumModel:(CAKAlbumModel * _Nullable)albumModel;

//iOS14 request access
- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didClickRequestAccessStartSettingButton:(UIView<CAKAlbumRequestAccessViewProtocol> * _Nullable)requestAccessView currentStatus:(PHAuthorizationStatus)status;
- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didClickDenyAccessStartSettingButton:(UIView<CAKAlbumRequestAccessViewProtocol> * _Nullable)denyAccessView;
- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didClickRequestAccessHintViewStartSetting:(UIView * _Nullable)requestAccessHintView;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didRequestAlbumAuthorizationWithStatus:(PHAuthorizationStatus)status;

- (void)albumViewController:(CAKAlbumViewController * _Nullable)album didShowRequestAccessHintView:(UIView * _Nullable)requestAccessHintView;

- (void)albumViewControllerPhotoLibraryDidChange:(CAKAlbumViewController * _Nullable)album;

@end


@interface CAKAlbumViewController : UIViewController <CAKSwipeInteractionControllerDelegate>

@property (nonatomic, weak, nullable) id<CAKAlbumViewControllerDataSource> dataSource;
@property (nonatomic, weak, nullable) id<CAKAlbumViewControllerDelegate> delegate;
@property (nonatomic, strong, nullable) id<CAKAlbumViewControllerDataSource> strongDataSource;
@property (nonatomic, strong, nullable) id<CAKAlbumViewControllerDelegate> strongDelegate;
@property (nonatomic, strong, nullable) CAKAlbumViewControllerNavigationView<CAKAlbumNavigationViewProtocol> *defaultNavigationView;
@property (nonatomic, strong, readonly, nullable) UIView<CAKAlbumBottomViewProtocol> *selectedAssetsBottomView;

@property (nonatomic, copy, readonly, nullable) NSArray<CAKAlbumAssetModel *> *selectedAlbumAssets;
@property (nonatomic, copy, readonly, nullable) NSArray<CAKAlbumAssetModel *> *selectedVideoAssets;
@property (nonatomic, copy, readonly, nullable) NSArray<CAKAlbumAssetModel *> *selectedPhotoAssets;

@property (nonatomic, strong, readonly, nullable) UIViewController<CAKAlbumListViewControllerProtocol> *currentListViewController;

// 内部会切换，不能再依赖 inputData 的初始值
@property (nonatomic, readonly) BOOL enablePreview;
@property (nonatomic, readonly) BOOL enableMultiSelect;

@property (nonatomic, weak, nullable) id prefetchData;

@end
