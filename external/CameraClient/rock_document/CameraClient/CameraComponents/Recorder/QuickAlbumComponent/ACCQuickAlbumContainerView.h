//
//  AWEQuickAlbumContainerView.h
//  ZYXHorizontalFlowLayout
//
//  Created by fengming.shi on 2020/11/27 14:34.
//	Copyright © 2020 Bytedance. All rights reserved.
	

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AWEAssetModel;
@class AWECircularProgressView;

@protocol ACCQuickAlbumContainerViewDelegate <NSObject>

- (void)quickAlbumCollectionViewDidSelected:(AWEAssetModel *)model completion:(void(^)(void))completion;

- (void)quickAlbumNeedLoadMore;

- (void)quickAlbumSwipeHide;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ACCQuickAlbumContainerView : UIView

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (void)setQuickAlbumDatasource:(NSArray <AWEAssetModel *> *)dataSource;
- (void)quickAlbumHasShow;
- (void)unobserveKVO;

@property (nonatomic, weak) id<ACCQuickAlbumContainerViewDelegate> delegate;

@end


@interface ACCQuickAlbumPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *photoImage;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UILabel *videoDurationLabel;
@property (nonatomic, strong) UIView *highlightMaskView;
@property (nonatomic, strong) AWECircularProgressView *progressView;
@property (nonatomic, strong) UIImageView *favoriteImageView;

- (void)configAlbumCellState:(BOOL)isFirstShow;

@end

NS_ASSUME_NONNULL_END
