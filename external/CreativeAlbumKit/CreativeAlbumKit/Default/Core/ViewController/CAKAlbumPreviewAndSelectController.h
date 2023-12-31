//
//  CAKAlbumPreviewAndSelectController.h
//  CameraClient
//
//  Created by lixingdong on 2020/7/17.
//

#import <UIKit/UIKit.h>
#import "CAKPhotoManager.h"
#import "CAKAlbumViewModel.h"
#import "CAKAlbumListViewConfig.h"

@class CAKAlbumAssetModel, CAKAlbumPreviewAndSelectController, CAKAlbumPreviewPageBottomView;

@protocol CAKAlbumPreviewAndSelectControllerDelegate <NSObject>

@optional
- (void)previewControllerDidLoad:(CAKAlbumPreviewAndSelectController * _Nullable)previewController forAlbumAsset:(CAKAlbumAssetModel * _Nullable)asset bottomView:(CAKAlbumPreviewPageBottomView * _Nullable)bottomView;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController scrollViewDidEndDeceleratingWithAlbumAsset:(CAKAlbumAssetModel * _Nullable)asset;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController didClickNextButton:(UIButton * _Nullable)btn;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController updateNextButtonTitle:(UIButton * _Nullable)btn;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController selectedAssetsViewdidDeleteAsset:(CAKAlbumAssetModel * _Nullable)deletedAsset;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController selectedAssetsViewDidClickAsset:(CAKAlbumAssetModel * _Nullable)asset;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController selectedAssetsViewDidChangeOrderWithDraggingAsset:(CAKAlbumAssetModel * _Nullable)asset;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController willBeginSetupPlayer:(AVPlayer * _Nullable)player status:(NSInteger)status;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController didFinishFetchIcloudWithFetchDuration:(NSTimeInterval)duration size:(NSInteger)size;
- (void)previewController:(CAKAlbumPreviewAndSelectController * _Nullable)previewController viewDidEndZoomingWithZoomIn:(BOOL)isZoomIn asset:(CAKAlbumAssetModel * _Nullable)asset;

@end

@interface CAKAlbumPreviewAndSelectController : UIViewController

@property (nonatomic, assign) BOOL greyMode;
@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, strong, readonly, nullable) CAKAlbumAssetModel *exitAssetModel;
@property (nonatomic, assign, readonly) BOOL currentAssetModelSelected;

@property (nonatomic, strong, nullable) NSArray<CAKAlbumAssetModel *> *selectedAssetModelArray;

@property (nonatomic, strong, nullable) NSArray<CAKAlbumAssetModel *> *originDataSource;
@property (nonatomic, weak, nullable) id<CAKAlbumPreviewAndSelectControllerDelegate> delegate;


@property (nonatomic, copy, nullable) void(^willDismissBlock)(CAKAlbumAssetModel * _Nullable currentModel);
@property (nonatomic, copy, nullable) void(^didClickedTopRightIcon)(CAKAlbumAssetModel * _Nullable currentModel, BOOL isSelected);

@property (nonatomic, assign) CAKAlbumAssetsSelectedIconStyle assetsSelectedIconStyle;

- (instancetype _Nonnull)initWithViewModel:(CAKAlbumViewModel * _Nullable)viewModel anchorAssetModel:(CAKAlbumAssetModel * _Nullable)anchorAssetModel;

- (instancetype _Nonnull)initWithViewModel:(CAKAlbumViewModel * _Nullable)viewModel anchorAssetModel:(CAKAlbumAssetModel * _Nullable)anchorAssetModel fromBottomView:(BOOL)fromBottomView;

- (void)reloadSelectedStateWithGrayMode:(BOOL)greyMode;

@end
