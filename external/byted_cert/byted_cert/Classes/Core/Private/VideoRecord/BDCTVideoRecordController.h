//
//  BDCTVideoRecordTimer.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/29.
//

#import "BytedCertVideoRecordParameter.h"
#import "FaceLiveModule.h"

#import <AVFoundation/AVFoundation.h>

@class BDCTVideoRecordController, BDCTFlow;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDCTVideoRecordResult) {
    BDCTVideoRecordResultUnknowError,
    BDCTVideoRecordResultCancel,
    BDCTVideoRecordResultInvalidFace,
    BDCTVideoRecordResultFaceCompareFail,
    BDCTVideoRecordResultSuccess
};

@protocol BDCTVideoRecordControllerDelegate <NSObject>

- (void)videoRecordController:(BDCTVideoRecordController *)controller countDownDidUpdate:(int)countDown;
- (void)videoRecordController:(BDCTVideoRecordController *)controller readProgressDidUpdate:(int)textIndex;
- (void)videoRecordController:(BDCTVideoRecordController *)controller faceDetectQualityDidChange:(NSString *)prompt;
- (void)videoRecordController:(BDCTVideoRecordController *)controller recordDidFinishWithResult:(BDCTVideoRecordResult)result videoPathURL:(NSURL *_Nullable)videoPathURL;

@end


@interface BDCTVideoRecordController : NSObject

+ (instancetype)controllerWithFlow:(BDCTFlow *)flow faceliveInstance:(FaceLiveModule *)faceliveInstance delegate:(id<BDCTVideoRecordControllerDelegate>)delegate;

- (void)recordWithCaptureOutput:(AVCaptureOutput *)captureOutput sampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (BOOL)shouldDetectFace;
- (void)hasDetectBestFaceFrameWithFaceData:(CVPixelBufferRef)faceData;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
