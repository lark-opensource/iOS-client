//
//  ACCEditVideoSmallPreviewController.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoSmallPreviewController : UIViewController

@property (nonatomic, strong, readonly) UIView *playerContainer;
@property (nonatomic, strong, readonly) UIButton *stopAndPlayBtn;

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
               stickerContainerView:(nullable ACCStickerContainerView *)stickerContainerView
                        previewSize:(CGSize)previewSize;

- (void)didClickStopAndPlay;

@end

NS_ASSUME_NONNULL_END
