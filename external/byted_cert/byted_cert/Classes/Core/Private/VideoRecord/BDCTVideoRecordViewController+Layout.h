//
//  BDCTVideoRecordViewController+Layout.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/16.
//

#import "BDCTVideoRecordViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTVideoRecordViewController (Layout)

@property (nonatomic, assign, readonly) CGRect recordFaceRect;

@property (nonatomic, strong, readonly) UILabel *startCountDownLabel;
@property (nonatomic, strong, readonly) UIButton *retryBtn;

#if DEBUG

@property (nonatomic, strong, readonly) UILabel *faceQualityLabel;

#endif

- (void)layoutContentViews;
- (BOOL)relayoutContentViewsIfNeeded;

- (void)updateFaceQualityText:(NSString *)text;

- (CGRect)layoutCapturePreviewIfNeededWithPixelSize:(CGSize)pixelSize;

- (void)resetReadTextHighLightProgress;

- (BOOL)updateReadTextHighLightProgress:(int)length;

@end

NS_ASSUME_NONNULL_END
