//
//  ACCLiveStickerEditView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCLiveStickerView;

@interface ACCLiveStickerEditView : UIView

@property (nonatomic, copy, nullable) dispatch_block_t editDidCompleted;

- (void)startEditSticker:(ACCLiveStickerView *)stickerView;

@end

NS_ASSUME_NONNULL_END
