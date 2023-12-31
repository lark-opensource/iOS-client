//
//  ACCStickerPreviewCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/24.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@interface ACCStickerPreviewCollectionViewCell : UICollectionViewCell

// For Subclass
@property (nonatomic, strong, readonly) UIImageView *iconImageView;
@property (nonatomic, strong, readonly) UILabel     *titleLabel;
- (void)setupUI;

- (void)configCellWithEffect:(IESEffectModel *)effect;

- (void)showCurrentTag:(BOOL)show;

- (void)updateDownloadStatus:(AWEEffectDownloadStatus)status;

+ (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
