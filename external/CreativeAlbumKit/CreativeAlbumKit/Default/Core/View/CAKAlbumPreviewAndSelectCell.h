//
//  CAKAlbumPreviewAndSelectCell.h
//  AWEStudio-Pods-Aweme
//
//  Created by xulei on 2020/3/15.
//

#import <UIKit/UIKit.h>

@class CAKAlbumAssetModel, AVPlayerLayer, CAKAlbumPreviewAndSelectCell;

@interface CAKAlbumPreviewAndSelectCell : UICollectionViewCell

@property (nonatomic, strong, nullable) UIScrollView *zoomScrollView;

@property (nonatomic, strong, nullable) CAKAlbumAssetModel *assetModel;
@property (nonatomic, copy, nullable) void (^fetchIcloudCompletion)(NSTimeInterval duration, NSInteger size);
@property (nonatomic, copy, nullable) void (^scrollViewDidZoomBlock)(CGFloat zoomScale);
@property (nonatomic, copy, nullable) void (^scrollViewDidEndZoomBlock)(CGFloat zoomScale, BOOL isZoomIn);

- (void)configCellWithAsset:(CAKAlbumAssetModel * _Nonnull)assetModel withPlayFrame:(CGRect)playFrame greyMode:(BOOL)greyMode;

/// just set hidden property
- (void)removeCoverImageView;
- (void)setPlayerLayer:(AVPlayerLayer * _Nonnull)playerLayer withPlayerFrame:(CGRect)playerFrame;

@end

