//
//  CAKAlbumAssetListCell.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/30.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumListViewConfig.h"

@class PHAsset, CAKAlbumAssetModel;

@protocol CAKAlbumAssetListCellAccessibilityProtocol
@optional
- (void)configAccessibilityElements;
- (void)updateSelectPhotoViewAccessibilityLabel;

@end

@interface CAKAlbumAssetListCell : UICollectionViewCell <CAKAlbumAssetListCellAccessibilityProtocol>

@property (nonatomic, strong, nullable) CAKAlbumAssetModel *assetModel;
@property (nonatomic, assign) CAKAlbumAssetsSelectedIconStyle assetsSelectedIconStyle;
@property (nonatomic, assign) BOOL checkMaterialRepeatSelect;
@property (nonatomic, assign) BOOL shouldAdjustThumbnailImageViewContentMode;
@property (nonatomic, strong, nullable) UIView *selectPhotoView;

@property (nonatomic, copy, nullable) void (^didSelectedAssetBlock)(CAKAlbumAssetListCell * _Nullable selectedCell, BOOL isSelected);
@property (nonatomic, copy, nullable) void (^didFetchThumbnailBlock)(NSTimeInterval duration);

- (void)updateSelectStatus;
- (void)configureCellWithAsset:(CAKAlbumAssetModel * _Nullable)assetModel greyMode:(BOOL)greyMode showRightTopIcon:(BOOL)show;
- (void)configureCellWithAsset:(CAKAlbumAssetModel * _Nullable)assetModel greyMode:(BOOL)greyMode showRightTopIcon:(BOOL)show alreadySelect:(BOOL)alreadySelect;
- (void)configureCellWithAsset:(CAKAlbumAssetModel * _Nullable)assetModel greyMode:(BOOL)greyMode showRightTopIcon:(BOOL)show showGIFMark:(BOOL)showGIFMark alreadySelect:(BOOL)alreadySelect;
- (void)doSelectedAnimation;
- (void)updateLeftCornerTagText:(NSString * _Nullable)text;
- (void)updateLeftCornerTagShow:(BOOL)show;
- (void)updateAssetsMultiSelectMode:(BOOL)showRightTopIcon withAsset:(CAKAlbumAssetModel * _Nullable)assetModel greyMode:(BOOL)greyMode;
- (void)updateGreyMode:(BOOL)greyMode withNum:(NSNumber * _Nullable)number;
- (void)updateNumberLabel:(NSNumber * _Nullable)number;
- (UIImage * _Nullable)thumbnailImage;

+ (NSString * _Nonnull)identifier;

- (void)enablefavoriteSymbolShow:(BOOL)show;

@end
