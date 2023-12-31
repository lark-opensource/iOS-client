//
//  CAKAlbumListViewControllerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/12/23.
//

#import <Foundation/Foundation.h>
#import "CAKPhotoManager.h"

NS_ASSUME_NONNULL_BEGIN
@class CAKAlbumAssetModel, AVAsset, AVPlayer, CAKAlbumPreviewPageBottomView;
@protocol CAKAlbumListViewControllerProtocol;

@protocol CAKAlbumListViewControllerDelegate <NSObject>

@optional

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didConfigCellForAsset:(CAKAlbumAssetModel *)assetModel;
- (BOOL)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC shouldSelectAsset:(CAKAlbumAssetModel *)assetModel;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didSelectedAsset:(CAKAlbumAssetModel *)assetModel isFromPreview:(BOOL)isFromPreview;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didDeselectAsset:(CAKAlbumAssetModel *)assetModel isFromPreview:(BOOL)isFromPreview;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didClickedCell:(CAKAlbumAssetModel *)assetModel;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerDidLoadForAlbumAsset:(CAKAlbumAssetModel *)assetModel bottomView:(CAKAlbumPreviewPageBottomView *)bottomView;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:(CAKAlbumAssetModel *)asset;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerSelectedAssetsViewDidDeleteAsset:(CAKAlbumAssetModel *)assetModel;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerSelectedAssetsViewDidClickAsset:(CAKAlbumAssetModel *)assetModel;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerSelectedAssetsViewDidChangeOrderWithAsset:(CAKAlbumAssetModel *)assetModel;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerWillBeginSetupPlayer:(AVPlayer *)player status:(NSInteger)status;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didFinishFetchIcloudWithFetchDuration:(NSTimeInterval)duration size:(NSInteger)size;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerDidClickNextButton:(UIButton *)btn;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerUpdateNextButtonTitle:(UIButton *)btn;
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerDidEndZoomingWithIsZoomIn:(BOOL)isZoomIn asset:(CAKAlbumAssetModel *)asset;
- (void)albumListVCEndPreview:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;

- (void)albumListVCDidLoad:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
- (void)albumListVCWillAppear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
- (void)albumListVCDidAppear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
- (void)albumListVCWillDisappear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
- (void)albumListVCScrollSelectAssetViewToNext:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
- (void)albumListVCUpdateEmptyCellForSelectedAssetView:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
- (void)albumListVCNeedShowAuthoritionDenyView:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;

@end

@class CAKAlbumListTabConfig, CAKAlbumBaseViewModel;

@protocol CAKAlbumListViewControllerProtocol <NSObject>

@property (nonatomic, weak) id<CAKAlbumListViewControllerDelegate> vcDelegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *tabIdentifier;
@property (nonatomic, assign) BOOL enableBottomViewShow;
@property (nonatomic, assign) BOOL enableSelectedAssetsViewShow;

@optional

@property (nonatomic, weak) CAKAlbumBaseViewModel *viewModel;
@property (nonatomic, assign) AWEGetResourceType resourceType;
@property (nonatomic, strong) CAKAlbumListTabConfig *tabConfig;

- (void)requestAuthorizationCompleted;
- (void)reloadData;
- (void)updateAssetsMultiSelectMode;
- (void)scrollAssetToVisible:(CAKAlbumAssetModel *)assetModel;
- (BOOL)isEmptyPhotoAlbum;
- (BOOL)isEmptyVideoeAlbum;
- (void)albumListShowTabDotIfNeed:(void (^)(BOOL showDot, UIColor *color))showDotBlock;
- (void)scrollToBottom;
- (void)updateCollectionViewContentInset;

@end

NS_ASSUME_NONNULL_END
