//
//  AWEStickerPickerStickerBaseCell.m
//  CameraClient
//
//  Created by Chipengliu on 2020/7/26.
//

#import "AWEStickerPickerStickerBaseCell.h"
#import "AWEStickerDownloadManager.h"

@interface AWEStickerPickerStickerBaseCell()

@property (nonatomic, assign, readwrite) BOOL stickerSelected;

@end

@implementation AWEStickerPickerStickerBaseCell

- (void)setSticker:(IESEffectModel *)sticker {
    _sticker = sticker;
    
    if (self.sticker.fileDownloadURLs.count > 0 && self.sticker.fileDownloadURI.length > 0) {
        if (self.sticker.downloaded) {
            self.stickerStatus = AWEStickerPickerCellStatusDownlodSuccessed;
        } else {
            NSNumber *progress = [[AWEStickerDownloadManager manager] stickerDownloadProgress:sticker];
            if (progress && progress.floatValue < 1.f) {
                self.stickerStatus = AWEStickerPickerCellStatusDownloding;
            } else {
                self.stickerStatus = AWEStickerPickerCellStatusDefault;
            }
        }
    } else {
        // set AWEStickerPickerCellStatusDownlodSuccessed as nothing needs to download
        self.stickerStatus = AWEStickerPickerCellStatusDownlodSuccessed;
    }
}

- (void)setStickerSelected:(BOOL)stickerSelected animated:(BOOL)animated
{
    _stickerSelected = stickerSelected;
}

- (void)updateStickerIconImage
{

}

@end
