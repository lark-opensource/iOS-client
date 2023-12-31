//
//  AWEPhotoPickerCollectionViewCell.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import <UIKit/UIKit.h>

@class AWEAssetModel;

NS_ASSUME_NONNULL_BEGIN

@interface AWEPhotoPickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong, nullable) AWEAssetModel *assetModel;

@property (nonatomic, assign) BOOL assetSelected;

+ (NSString *)identifier;

@end

@interface AWEPhotoPickerCollectionViewMultiAssetsCell : AWEPhotoPickerCollectionViewCell

@end

NS_ASSUME_NONNULL_END
