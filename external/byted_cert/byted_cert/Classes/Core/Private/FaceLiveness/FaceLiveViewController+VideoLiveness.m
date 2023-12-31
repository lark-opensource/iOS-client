//
//  FaceLiveViewController+VideoLiveness.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/16.
//

#import "FaceLiveViewController+VideoLiveness.h"
#import "FaceLiveViewController+Layout.h"
#import "BDCTEventTracker+VideoLiveness.h"
#import "VideoLivenessTC.h"
#import "BDCTLocalization.h"
#import "BDCTStringConst.h"
#import "BDCTIndicatorView.h"
#import "BDCTAPIService.h"
#import "UIImage+BDCTAdditions.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@interface BytedCertVideoValidateLoadingView : UIView

@property (nonatomic, strong) UIImageView *loadingView;

@end


@implementation BytedCertVideoValidateLoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    }
    return self;
}

- (UIImageView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIImageView alloc] initWithFrame:self.bounds];
        _loadingView.image = [UIImage bdct_loadingImage];
        _loadingView.contentMode = UIViewContentModeCenter;
        [_loadingView sizeToFit];
        [_loadingView.layer removeAllAnimations];
        CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotateAnimation.duration = 1.0f;
        rotateAnimation.repeatCount = HUGE_VAL;
        rotateAnimation.toValue = @(M_PI * 2);
        [_loadingView.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
        [self addSubview:_loadingView];
    }
    return _loadingView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.loadingView.frame = self.bounds;
}

@end


@interface BytedCertVideoLivenessReadNumberView ()

@property (nonatomic, assign) int maxLength;

@end


@implementation BytedCertVideoLivenessReadNumberView

- (void)setMaxLength:(int)maxLength {
    if (_maxLength == maxLength) {
        return;
    }
    _maxLength = maxLength;
    for (int i = 0; i < _maxLength; i++) {
        UILabel *label = [UILabel new];
        label.font = self.font;
        label.textColor = self.textColor;
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
    }
}

- (void)clear {
    [self updateNumber:nil maxLength:0];
}

- (void)updateNumber:(NSString *)number maxLength:(int)maxLength {
    if (!number.length || maxLength <= 0) {
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UILabel *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [obj setText:@""];
        }];
        return;
    }
    self.maxLength = maxLength;
    __block CGFloat originX = 0;
    __block CGFloat spacing = 0;
    __block CGFloat contentHeight = 0;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UILabel *_Nonnull label, NSUInteger idx, BOOL *_Nonnull stop) {
        if (idx < number.length) {
            [label setText:[number substringWithRange:NSMakeRange(idx, 1)]];
            label.alpha = 1;
        } else {
            [label setText:@"·"];
            label.alpha = 0.4;
        }
        [label sizeToFit];
        if (idx == 0) {
            contentHeight = label.bounds.size.height;
            CGRect frame = self.frame;
            frame.size.height = contentHeight;
            self.frame = frame;
            spacing = (self.bounds.size.width - contentHeight * maxLength) / (maxLength - 1);
        }
        label.frame = CGRectMake(originX, 0, contentHeight, contentHeight);
        originX = originX + contentHeight + spacing;
    }];
}

@end


@implementation FaceLiveViewController (VideoLiveness)

- (BytedCertVideoLivenessReadNumberView *)readNumberView {
    static int readNumViewTag = 1024 * 3;
    BytedCertVideoLivenessReadNumberView *readNumberView = [self.view viewWithTag:readNumViewTag];
    if (!readNumberView) {
        readNumberView = [BytedCertVideoLivenessReadNumberView new];
        readNumberView.font = BytedCertUIConfig.sharedInstance.readNumberLabelFont;
        CGFloat width = self.cropCircleRect.size.width - 15 * 2;
        readNumberView.frame = CGRectMake(self.view.center.x - width / 2.0, CGRectGetMaxY(self.cropCircleRect) + 48, width, 0);
        readNumberView.textColor = BytedCertUIConfig.sharedInstance.textColor;
        readNumberView.tag = readNumViewTag;
        [self.view insertSubview:readNumberView aboveSubview:self.mainWrapperView];
    }
    return readNumberView;
}

//code 上传失败错误码
- (void)doUpload:(NSString *)videoPath resultCode:(int)code {
    dispatch_async(dispatch_get_main_queue(), ^{
        BytedCertVideoValidateLoadingView *loadingView = [BytedCertVideoValidateLoadingView new];
        loadingView.frame = self.cropCircleRect;
        self.actionTipLabel.text = BytedCertLocalizedString(@"核验中");
        [self.view insertSubview:loadingView belowSubview:self.mainWrapperView];

        NSString *ticketStr = self.bdct_flow.context.parameter.ticket ?: @"";
        NSData *videoData = [NSData dataWithContentsOfFile:videoPath];

        NSString *readNumber = [self.livenessTC valueForKey:NSStringFromSelector(@selector(readNumber))];
        int interruptTime = [[self.livenessTC valueForKey:NSStringFromSelector(@selector(interruptTime))] intValue];
        [self.bdct_flow.apiService bytedUploadVideo:self.bdct_flow.context.liveDetectRequestParams videoData:videoData callback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
            [loadingView removeFromSuperview];
            self.actionTipLabel.text = @"";
            if (error) {
                if (error.errorCode == BytedCertErrorVideoVerifyFailrure) {
                    [self.bdct_flow.eventTracker trackFaceDetectionImageResult:BytedCertTrackerFaceImageTypeFail];
                } else if (error.errorCode == BytedCertErrorVideoLivenessFailure) {
                    [self.bdct_flow.eventTracker trackVideoLivenessDetectionResultWithReadNumber:readNumber interuptTimes:interruptTime error:error];
                }
                if (error.errorCode == BytedCertErrorVideoLivenessFailure || error.errorCode == BytedCertErrorVideoVerifyFailrure) {
                    //delete file
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [fileManager removeItemAtPath:videoPath error:nil];

                    NSString *title = [self.livenessTC getLivenessErrorTitle:(int)error.errorCode];
                    NSString *msg = [self.livenessTC getLivenessErrorMsg:(int)error.errorCode];
                    [self liveDetectFailWithErrorTitle:title message:msg actionCompletion:^(NSString *action) {
                        [self.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:action failReason:[bdct_log_event_video_liveness_fail_reasons() btd_stringValueForKey:@(error.errorCode)] errorCode:error.errorCode];
                    }];
                } else {
                    [self showReuploadAlert:videoPath code:code actionCompletion:^(NSString *action) {
                        [self.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:action failReason:@"视频上传失败" errorCode:error.errorCode];
                    }];
                    return; //no delete
                }
            } else {
                [self.bdct_flow.eventTracker trackFaceDetectionImageResult:BytedCertTrackerFaceImageTypeSuccess];
                [self.bdct_flow.eventTracker trackVideoLivenessDetectionResultWithReadNumber:readNumber interuptTimes:interruptTime error:nil];
                //return verify resut
                NSDictionary *respDict = @{
                    @"status_code" : @(0),
                    @"data" : @{
                        @"ticket" : (ticketStr ?: @"")
                    }
                };
                [self callbackWithResult:respDict error:nil];
            }
        }];
    });
}

- (void)showReuploadAlert:(NSString *)path code:(int)code actionCompletion:(void (^)(NSString *))actionCompletion {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = [self.livenessTC getLivenessErrorTitle:code];
        NSString *msg = [self.livenessTC getLivenessErrorMsg:code];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *quit = [UIAlertAction actionWithTitle:BytedCertLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
            // 退出
            //delete file
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:path error:nil];

            [self callbackWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorLiveness]];
            if (actionCompletion)
                actionCompletion(@"quit");
        }];
        [alert addAction:quit];

        UIAlertAction *retryAction = [UIAlertAction actionWithTitle:BytedCertLocalizedString(@"重试") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            // 再试一次
            [self doUpload:path resultCode:code];
            if (actionCompletion)
                actionCompletion(@"retry");
        }];

        [alert addAction:retryAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
