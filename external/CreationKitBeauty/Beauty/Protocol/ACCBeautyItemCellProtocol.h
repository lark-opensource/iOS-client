//
//  ACCBeautyItemCellProtocol.h
//  CameraClient
//
//  Created by zhangyuanming on 2020/8/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBeautyItemCellProtocol <NSObject>

@property (nonatomic, assign) AWEBeautyCellIconStyle iconStyle;
- (void)configWithBeauty:(AWEComposerBeautyEffectWrapper *)beautyWrapper;
- (void)makeSelected;
- (void)makeDeselected;
- (void)setIconImage:(UIImage *)image;
- (void)setDownloadStatus:(AWEEffectDownloadStatus)downloadStatus;
- (void)setShouldShowAppliedIndicator:(BOOL)shouldShow;
- (void)setShouldShowAppliedIndicatorWhenSwitchIsEnabled:(BOOL)shouldShow;
// if current beauty item intensity == 0, not applied
// if current beauty item intensity > 0,  applied
- (void)setApplied:(BOOL)applied;
- (void)enableCellItem:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
