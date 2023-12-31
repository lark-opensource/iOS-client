//
//  BDCTVideoRecordTimer.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/29.
//

#import "BDCTVideoRecordController.h"
#import "BDCTVideoRecorder.h"
#import "BDCTFlow.h"
#import "BDCTAPIService.h"
#import "FaceLiveUtils.h"
#import "BDCTEventTracker.h"
#import "BytedCertManager+Private.h"
#import "BDCTAdditions.h"
#import "BDCTFlowContext.h"
#import "BDCTStringConst.h"

#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDAssert/BDAssert.h>


@interface BDCTVideoRecordController ()
{
    dispatch_queue_t _controllerQueue;
    dispatch_queue_t _faceDetectQueue;
}

@property (nonatomic, strong) BytedCertVideoRecordParameter *parameter;

@property (nonatomic, weak) id<BDCTVideoRecordControllerDelegate> delegate;
@property (nonatomic, weak) BDCTFlow *flow;

@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, assign) double recordStartTime;
@property (nonatomic, assign) double readTextStartTime;
@property (nonatomic, assign) double readTextEndTime;
@property (nonatomic, assign) double recordEndTime;

@property (nonatomic, assign) BOOL hasBestFrameInFirst5s;
@property (nonatomic, assign) BOOL hasBestFrameInLast5s;

@property (nonatomic, assign) int progressTag;

@property (nonatomic, strong) BDCTVideoRecorder *videoRecorder;
@property (nonatomic, strong) FaceLiveModule *faceliveInstance;

@end


@implementation BDCTVideoRecordController

+ (instancetype)controllerWithFlow:(BDCTFlow *)flow faceliveInstance:(FaceLiveModule *)faceliveInstance delegate:(id<BDCTVideoRecordControllerDelegate>)delegate {
    BDCTVideoRecordController *controller = [BDCTVideoRecordController new];
    controller.flow = flow;
    controller.parameter = (BytedCertVideoRecordParameter *)flow.context.parameter;
    controller.faceliveInstance = faceliveInstance;
    controller.delegate = delegate;
    return controller;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isRecording = YES;
        _controllerQueue = dispatch_queue_create("com.bytedance.cert.videorecord.controller", DISPATCH_QUEUE_SERIAL);
        _faceDetectQueue = dispatch_queue_create("com.bytedance.cert.videorecord.facedetect", DISPATCH_QUEUE_SERIAL);
        NSString *tmpFileName = [NSString stringWithFormat:@"byted_cert_video_record_athorizarion.mp4"];
        NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFileName]];
        if ([NSFileManager.defaultManager fileExistsAtPath:outputURL.path]) {
            [NSFileManager.defaultManager removeItemAtURL:outputURL error:nil];
        }
        _videoRecorder = [[BDCTVideoRecorder alloc] initWithOutputURL:outputURL];
    }
    return self;
}

- (void)cancel {
    dispatch_async(_controllerQueue, ^{
        [self p_stopVideoRecordWithResult:BDCTVideoRecordResultInvalidFace];
    });
}

- (void)recordWithCaptureOutput:(AVCaptureOutput *)captureOutput sampleBuffer:(CMSampleBufferRef)sampleBuffer {
    @autoreleasepool {
        @weakify(self);
        CFRetain(sampleBuffer);
        dispatch_async(_controllerQueue, ^{
            @strongify(self);
            if (self.isRecording) {
                [self.videoRecorder appendSampleBuffer:sampleBuffer mediaType:([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]] ? AVMediaTypeVideo : AVMediaTypeAudio)];
                [self p_updateProgress];
                if ([captureOutput isKindOfClass:AVCaptureVideoDataOutput.class]) {
                    [self p_faceDetect:sampleBuffer];
                }
            }
            CFRelease(sampleBuffer);
        });
    }
}

- (void)p_updateProgress {
    if (!self.isRecording) {
        return;
    }
    if (self.recordStartTime <= 0) {
        self.recordStartTime = [[NSDate date] timeIntervalSince1970];
    }
    NSTimeInterval timeProgress = [[NSDate date] timeIntervalSince1970] - self.recordStartTime;
    if (timeProgress <= 3) {
        [self.delegate videoRecordController:self countDownDidUpdate:(3 - (int)timeProgress)];
        return;
    }
    [self.delegate videoRecordController:self countDownDidUpdate:0];
    if (self.readTextStartTime <= 0) {
        self.readTextStartTime = [[NSDate date] timeIntervalSince1970];
    }
    int readTextLength = MIN((timeProgress - 3) * 1000.0 / self.parameter.msPerWord + 1, self.parameter.readText.length);
    [self.delegate videoRecordController:self readProgressDidUpdate:readTextLength];
    if (readTextLength >= self.parameter.readText.length && self.readTextEndTime <= 0) {
        self.readTextEndTime = [[NSDate date] timeIntervalSince1970];
    }
    if (self.readTextEndTime > 0 && [[NSDate date] timeIntervalSince1970] - self.readTextEndTime >= 3 && self.recordEndTime <= 0) {
        self.recordEndTime = [[NSDate date] timeIntervalSince1970];
        [self p_updateProgressTag];
    }
}

- (void)p_faceDetect:(CMSampleBufferRef)sampleBuffer {
    if (!self.isRecording) {
        return;
    }
    @weakify(self);
    CFRetain(sampleBuffer);
    dispatch_async(_faceDetectQueue, ^{
        @strongify(self);
        if (self == nil) {
            return;
        }
        FaceQualityInfo info;
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        [self.faceliveInstance doFaceQuality:pixelBuffer orient:[UIDevice bdct_deviceOrientation] ret:&info];
        CFRetain(pixelBuffer);
        dispatch_async(self->_controllerQueue, ^{
            if (self.p_shouldDetectFace) {
                // 人脸质量检测合格
                if (info.prompt == 6) {
                    [self p_hasDetectBestFaceFrameWithFaceData:pixelBuffer];
                }
            }
            CFRelease(pixelBuffer);
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *faceDetectPrompt = [bdct_video_status_strs() btd_objectAtIndex:info.prompt];
            [self.delegate videoRecordController:self faceDetectQualityDidChange:faceDetectPrompt];
        });
        CFRelease(sampleBuffer);
    });
}

- (void)p_updateProgressTag {
    if (!self.isRecording) {
        return;
    }
    self.progressTag = self.progressTag + 1;
    BDAssert(self.progressTag <= 3, @"Should not reach here.");
    if (self.progressTag == 3 || self.parameter.skipFaceDetect) {
        [self p_stopVideoRecordWithResult:BDCTVideoRecordResultSuccess];
    }
}

- (void)p_stopVideoRecordWithResult:(BDCTVideoRecordResult)result {
    if (!self.isRecording) {
        return;
    }
    self.isRecording = NO;
    @weakify(self);
    [self.videoRecorder finishWritingWithCompletion:^(AVAssetWriterStatus status, NSURL *_Nonnull fileURL, NSError *_Nullable error) {
        @strongify(self);
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
        long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil] fileSize];
        [BDCTEventTracker trackWithEvent:@"byted_cert_video_record_result" params:@{
            @"file_exists" : @(fileExists),
            @"file_size" : @(fileSize),
            @"result" : @(result),
            @"error" : (error ?: @"")
        }];
        if (result != BDCTVideoRecordResultSuccess) {
            if (fileExists) {
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
            }
            [self.delegate videoRecordController:self recordDidFinishWithResult:result videoPathURL:fileURL];
            return;
        }
        if (!fileExists || fileSize <= 0) {
            [self.delegate videoRecordController:self recordDidFinishWithResult:BDCTVideoRecordResultUnknowError videoPathURL:fileURL];
            return;
        }
        [self.delegate videoRecordController:self recordDidFinishWithResult:result videoPathURL:fileURL];
    }];
}

- (BOOL)p_shouldDetectFace {
    if (!self.isRecording || self.parameter.skipFaceDetect || self.readTextStartTime <= 0) {
        return NO;
    }
    double currentTime = [[NSDate date] timeIntervalSince1970];
    // 5秒前和5秒后要检测人脸
    if (currentTime - self.readTextStartTime <= 5) {
        if (!self.hasBestFrameInFirst5s) {
            return YES;
        }
    } else if (!self.hasBestFrameInFirst5s) {
        // 检测失败 结束流程
        [self p_stopVideoRecordWithResult:BDCTVideoRecordResultInvalidFace];
        return NO;
    }

    if (currentTime - self.readTextStartTime > self.parameter.totalReadDurationInSeconds) {
        if (!self.hasBestFrameInLast5s) {
            // 检测失败 结束流程
            [self p_stopVideoRecordWithResult:BDCTVideoRecordResultInvalidFace];
            return NO;
        }
    } else if (self.parameter.totalReadDurationInSeconds - (currentTime - self.readTextStartTime) <= 5) {
        if (!self.hasBestFrameInLast5s) {
            return YES;
        }
    }
    return NO;
}

- (void)p_hasDetectBestFaceFrameWithFaceData:(CVPixelBufferRef)pixelBufferRef {
    if (!_isRecording) {
        return;
    }
    int repeatTimes = 1;
    if (!self.hasBestFrameInFirst5s) {
        self.hasBestFrameInFirst5s = YES;
    } else if (!self.hasBestFrameInLast5s) {
        repeatTimes = 2;
        self.hasBestFrameInLast5s = YES;
    }
    NSData *videoFaceData;

    CVImageBufferRef imageBuffer = pixelBufferRef;
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    videoFaceData = [FaceLiveUtils convertRawBufferToImage:baseAddress imageName:@"env.jpg" cols:(int)width rows:(int)height saveImage:false];
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    NSMutableDictionary *faceDataMap = [NSMutableDictionary dictionary];
    BDAssert(self.parameter.faceEnvBase64.length, @"faceEnvBase64 must not be nil");
    faceDataMap[@"image"] = [videoFaceData base64EncodedStringWithOptions:0];
    faceDataMap[@"ref_image"] = self.parameter.faceEnvBase64;
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        if (!self.parameter.faceEnvBase64.length) {
    //            return;
    //        }
    //        NSData *decodedImageData = [[NSData alloc] initWithBase64EncodedString:self.parameter.faceEnvBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    //        UIImage *d = [UIImage imageWithData:decodedImageData];
    //        if (d) {
    //        }
    //        d = [UIImage imageWithData:videoFaceData];
    //        if (d) {
    //        }
    //    });
    OSType format = CVPixelBufferGetPixelFormatType(pixelBufferRef);
    @weakify(self);
    [self.flow.apiService authSubmitWithParams:@{@"liveness_type" : @"server_face_comp", @"ref_source" : @"passive", @"repeat_times" : @(repeatTimes)} completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        [self.flow.apiService bytedfaceCompare:@{} progressType:self.parameter.mode sdkData:[FaceLiveUtils buildFaceCompareSDKDataWithParams:faceDataMap] callback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
            @strongify(self);
            if (self == nil) {
                return;
            }
            dispatch_async(self->_controllerQueue, ^{
                if (error != nil) {
                    [self p_stopVideoRecordWithResult:BDCTVideoRecordResultFaceCompareFail];
                } else {
                    [self p_updateProgressTag];
                }
            });
        }];
    }];
}

- (void)dealloc {
    BDALOG_PROTOCOL_DEBUG_TAG(NSStringFromClass(self.class), @"dealloc");
}

@end
