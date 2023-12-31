//
//  AWEStickerPickerStickerBaseCell.h
//  CameraClient
//
//  Created by Chipengliu on 2020/7/26.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWEStickerPickerCellStatus) {
    AWEStickerPickerCellStatusDefault           = 0, // default status, before download effect
    AWEStickerPickerCellStatusDownloding        = 1, // status for downloading effect
    AWEStickerPickerCellStatusDownlodSuccessed  = 2, // specifies status when all resource of effect download task finished
    AWEStickerPickerCellStatusDownlodFailed     = 3  // specifies status when all resource of effect download task failed
};

// The AWEStickerPickerStickerBaseCell class is provided as an abstract class for subclassing to define custom collection cell.
@interface AWEStickerPickerStickerBaseCell : UICollectionViewCell

// Override these methods to provide custom UI for a selected or highlighted state
@property (nonatomic, strong, nullable) IESEffectModel *sticker;
@property (nonatomic, assign, readonly) BOOL stickerSelected;
@property (nonatomic, assign) AWEStickerPickerCellStatus stickerStatus;
@property (nonatomic, strong) UIColor *selectedBorderColor;

- (void)setStickerSelected:(BOOL)stickerSelected animated:(BOOL)animated NS_REQUIRES_SUPER;

- (void)updateStickerIconImage;

@end

NS_ASSUME_NONNULL_END
