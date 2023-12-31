//
//  ACCPollStickerEditView.h
//  CameraClient-Pods-Aweme
//
//  Created by aloes on 2020/9/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCPollStickerView;

@interface ACCPollStickerEditView : UIView

@property (nonatomic, copy) void (^finishEditBlock) (void);
@property (nonatomic, copy) void (^startEditBlock) (void);
@property (nonatomic, copy) void (^takeScreenShotRecover) (ACCPollStickerView *stickerView);

- (void)startEditStickerView:(ACCPollStickerView *)stickerView;

@end

NS_ASSUME_NONNULL_END
