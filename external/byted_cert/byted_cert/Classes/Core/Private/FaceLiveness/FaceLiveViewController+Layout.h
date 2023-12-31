//
//  FaceLiveViewController+Layout.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/25.
//

#import "FaceLiveViewController.h"
#import "BDCTCaptureRenderView.h"

NS_ASSUME_NONNULL_BEGIN


@interface FaceLiveViewController (Layout)

@property (nonatomic, strong, readonly) UILabel *topbarTitleLabel;
@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UIButton *audioSwitchButton;
@property (nonatomic, strong, readonly) UIImageView *mainWrapperView;
@property (nonatomic, strong, readonly) UIView<BDCTCaptureRenderProtocol> *captureRenderView;
@property (nonatomic, strong, readonly) UILabel *actionTipLabel;
@property (nonatomic, strong, readonly) BDCTAlignLabel *smallActionTipLabel;
@property (nonatomic, strong, readonly) CAShapeLayer *circleProgressTrackLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *circleProgressBackgroundLayer;
///活体流程优化实验
@property (nonatomic, strong, readonly) UILabel *actionCountTipLabel;

@property (nonatomic, assign, readonly) CGRect cropCircleRect;
///护脸计划元素
@property (nonatomic, strong, readonly) UIImageView *trustWorthyLogo;
@property (nonatomic, strong, readonly) UIImageView *inspectionCenterLogo;
@property (nonatomic, strong, readonly) UILabel *protectFaceLable;

- (void)layoutContentViews;
- (void)layoutPreviewIfNeededWithPixelBufferSize:(CGSize)pixelBufferSize;
- (void)showContinueAlertWithDismissBlock:(void (^_Nullable)(BOOL))dismissBlock;
@end

NS_ASSUME_NONNULL_END
