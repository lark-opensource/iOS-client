//
//  HTSVideoFilterTableViewCell.h
//  Pods
//
//Created by he Hai on 16 / 7 / 7
//
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>
@class IESEffectModel;

@interface HTSVideoFilterTableViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, assign) BOOL enableSliderMaskImage;
@property (nonatomic, assign) AWEEffectDownloadStatus downloadStatus;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, assign) AWEFilterCellIconStyle iconStyle;

- (void)configWithFilter:(IESEffectModel *)filter;
- (void)setCenterImage:(UIImage *)image;
- (void)setFlagDotViewHidden:(BOOL)hidden;
- (nullable NSString *)getEffectName;

@end
