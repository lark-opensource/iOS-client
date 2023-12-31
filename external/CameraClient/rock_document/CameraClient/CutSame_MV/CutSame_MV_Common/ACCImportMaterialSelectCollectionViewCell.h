//
//  ACCImportMaterialSelectCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/5.
//

#import <UIKit/UIKit.h>
#import <CreativeAlbumKit/CAKAlbumAssetModel.h>
#import <CameraClient/AWEAssetModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCImportMaterialSelectCollectionViewCellModel : NSObject

@property (nonatomic, strong, nullable) CAKAlbumAssetModel *assetModel;

@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) BOOL highlight;

@property (nonatomic, assign) BOOL shouldShowDuration;

@property (nonatomic, assign) BOOL shouldChangeCellColor;

@end

@interface ACCImportMaterialSelectCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy) void (^deleteAction)(ACCImportMaterialSelectCollectionViewCell *cell);

@property (nonatomic, copy) NSIndexPath *currentIndexPath;

@property (nonatomic, strong) ACCImportMaterialSelectCollectionViewCellModel *cellModel;

- (void)bindModel:(ACCImportMaterialSelectCollectionViewCellModel *)cellModel;

@end

NS_ASSUME_NONNULL_END
