//
//  VideoLivenessTC.m
//  Pods
//
//  Created by zhengyanxin on 2021/3/1.
//

#import "VideoLivenessTC.h"
#import "FaceLiveViewController+Layout.h"
#import "FaceLiveModule.h"
#import "BDCTLocalization.h"
#import "BDCTVideoRecorder.h"
#import "BytedCertInterface.h"
#import "BDCTEventTracker+VideoLiveness.h"
#import "FaceLiveViewController+VideoLiveness.h"
#import "BDCTStringConst.h"
#import "BDCTFlow.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@interface VideoLivenessTC ()
{
    BDCTVideoRecorder *_srcVideoRecorder;
    NSString *_recordTimeStamp;
    BOOL _srcVideoWritten;
    dispatch_block_t delayStopVideoBlock;
    dispatch_block_t delayNumberBlock;
}

@property (nonatomic, strong) FaceLiveModule *faceliveInstance;

//log track
@property (nonatomic, assign) int prevMotion;
@property (nonatomic, assign) int frameCount;

//logic control
@property (atomic, assign) BOOL isDetecting;

@property (atomic, assign) BOOL mCanUpload;

/// 中断次数
@property (nonatomic, assign) NSInteger interruptTimes;

@property (nonatomic, weak) FaceLiveViewController *faceVC;

@property (nonatomic, assign) NSInteger lastTipsTime; //控制快切
@property (nonatomic, assign, readwrite) int interruptTime;
@property (nonatomic, assign) NSInteger startTime;

@property (atomic, assign) NSInteger recordState; //0 可以开始录制；1 启动录制中；2 录制中；3 停止录制中

@property (nonatomic, copy, readwrite) NSString *readNumber;

@property (atomic, assign) NSInteger curNumIndex;

@property (nonatomic, strong) NSMutableArray *promptRecordArray;

@end


@implementation VideoLivenessTC

- (instancetype)initWithVC:(FaceLiveViewController *)vc {
    self = [super init];
    if (!self) {
        return nil;
    }

    _faceVC = vc;
    _faceliveInstance = [[FaceLiveModule alloc] init];
    _lastTipsTime = 0;
    _interruptTime = 0;
    _startTime = 0;
    _curNumIndex = 0;
    _recordState = 0;
    _promptRecordArray = [NSMutableArray array];
    _lastTipsTime = NSDate.date.timeIntervalSince1970 * 1000;
    self.isDetecting = YES;
    self.mCanUpload = NO;
    return self;
}

- (int)setInitParams:(NSDictionary *)params {
    self.readNumber = params[@"random_number"];
    if (self.readNumber == nil) {
        self.readNumber = @"0000";
    }
    return 0;
}

- (int)setParamsGeneral:(int)type value:(float)value {
    return [_faceliveInstance setParamsGeneral:type value:value];
}

- (void)reStart:(int)type {
    _lastTipsTime = 0;
    _interruptTime = 0;
    _startTime = 0;
    _curNumIndex = 0;
    _recordState = 0;
    [_promptRecordArray removeAllObjects];
    self.isDetecting = YES;
    self.mCanUpload = NO;
    [self.faceliveInstance reStart];
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixels
                  orient:(ScreenOrient)orient {
    if (!self.isDetecting)
        return nil;
    NSInteger curTime = NSDate.date.timeIntervalSince1970 * 1000;
    if (curTime - self.lastTipsTime < 500) {
        return nil;
    }
    self.lastTipsTime = curTime;
    if (self.startTime == 0)
        self.startTime = curTime;

    FaceQualityInfo info;
    int status = [_faceliveInstance doFaceQuality:pixels orient:orient ret:&info];
    NSLog(@"status = %d ; info.prompt = %d", status, info.prompt);
    if (status != 0) {
        return nil;
    }

    unsigned long height = CVPixelBufferGetHeight(pixels);
    unsigned long width = CVPixelBufferGetWidth(pixels);
    NSString *boardStr;

    if (info.prompt >= 0 && info.prompt < [bdct_video_status_strs() count]) {
        boardStr = [bdct_video_status_strs() btd_objectAtIndex:info.prompt];
    } else {
        return nil;
    }

    if (info.prompt != 6 && info.prompt > 1) {
        [_promptRecordArray addObject:@(info.prompt)];
        //face quality not pass

        //stop recording and show number
        if (_recordState == 2) {
            _recordState = 3;
            //stop video
            dispatch_block_cancel(self->delayStopVideoBlock);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopRecord:NO];
            });

            self.interruptTime++;
            NSLog(@"video interruptTime %d", self.interruptTime);
            NSInteger costTime = NSDate.date.timeIntervalSince1970 * 1000 - self.startTime;
            NSLog(@"video costTime %ld", (long)costTime);
            if (self.interruptTime > 5 || costTime > 30 * 1000) {
                [self.faceVC.bdct_flow.eventTracker trackVideoLivenessDetectionResultWithReadNumber:_readNumber interuptTimes:_interruptTime error:[[BytedCertError alloc] initWithType:BytedCertErrorInterruptionLimit]];
                self.isDetecting = NO;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.faceVC liveDetectFailWithErrorTitle:[self getLivenessErrorTitle:2] message:[self getLivenessErrorMsg:2] actionCompletion:^(NSString *_Nonnull action) {
                        [self.faceVC.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:action failReason:[bdct_log_event_video_liveness_fail_reasons() btd_stringValueForKey:@(BytedCertErrorInterruptionLimit)] errorCode:0];
                    }];
                });
            }
        } else if (_recordState == 0) {
            [self.faceVC.bdct_flow.eventTracker trackVideoLivenessDetectionFaceQualityResult:NO promptInfo:_promptRecordArray];
            [self.faceVC.bdct_flow.eventTracker trackVideoLivenessDetectionResultWithReadNumber:_readNumber interuptTimes:_interruptTime error:[[BytedCertError alloc] initWithType:BytedCertErrorFaceQualityOverTime]];
            //一直质量不好，没录制
            NSInteger costTime = NSDate.date.timeIntervalSince1970 * 1000 - self.startTime;
            NSLog(@"video costTime %ld", (long)costTime);
            if (costTime > 30 * 1000) {
                self.isDetecting = NO;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.faceVC liveDetectFailWithErrorTitle:[self getLivenessErrorTitle:2] message:[self getLivenessErrorMsg:2] actionCompletion:^(NSString *_Nonnull action) {
                        [self.faceVC.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:action failReason:[bdct_log_event_video_liveness_fail_reasons() btd_stringValueForKey:@(BytedCertErrorFaceQualityOverTime)] errorCode:0];
                    }];
                });
            }
        }
    } else {
        //if no recording start
        if (_recordState == 0) {
            _recordState = 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startRecord:width height:height];
            });
        }

        boardStr = BytedCertLocalizedString(@"请用普通话大声读出数字");

        // 人脸检测通过
        if (_promptRecordArray.lastObject && [_promptRecordArray.lastObject intValue] != 6) {
            [self.faceVC.bdct_flow.eventTracker trackVideoLivenessDetectionFaceQualityResult:YES promptInfo:_promptRecordArray];
            [_promptRecordArray removeAllObjects];
        }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        self.faceVC.actionTipLabel.text = boardStr;
    });
    return nil;
}

- (void)viewDismiss {
}

- (NSDictionary *)packSDKData:(BOOL)isSuccess {
    NSDictionary *dict = @{
        @"sdk_data" : @"",
        @"image_env" : @"",
        @"image_face" : @""
    };
    return dict;
}

- (void)trackCancel {
}

- (int)getAlgoErrorCode {
    return _faceliveInstance.algoErrorCode;
}

- (NSString *)getLivenessErrorTitle:(int)code {
    if (code == 2) { //超时
        return BytedCertLocalizedString(@"操作超时");
    } else if (code == 3) { //上传失败
        return BytedCertLocalizedString(@"上传失败");
    }
    return BytedCertLocalizedString(@"核验失败");
}

- (NSString *)getLivenessErrorMsg:(int)code {
    if (code == 2) { //超时
        return BytedCertLocalizedString(@"正对手机，面部和背景无强光，更容易成功");
    } else if (code == 3) { //上传失败
        return BytedCertLocalizedString(@"网络请求失败，请重试");
    }
    if (code == BytedCertErrorVideoLivenessFailure) {
        return BytedCertLocalizedString(@"请用普通话大声读出数字");
    } else if (code == BytedCertErrorVideoVerifyFailrure) {
        return BytedCertLocalizedString(@"请确保本人进行校验");
    }
    return BytedCertLocalizedString(@"核验失败");
}

- (void)startRecord:(int)width height:(int)height {
    NSLog(@"start Record width %d height %d", width, height);

    //start
    [self generateDCTimeStampFilePath];
    NSInteger bitRate = width * height * 8;
    NSString *outputFile = [NSString stringWithFormat:@"%@_src.mp4", _recordTimeStamp];
    NSURL *outputURL = [NSURL fileURLWithPath:outputFile];
    _srcVideoRecorder = [[BDCTVideoRecorder alloc] initWithOutputURL:outputURL];
    _srcVideoWritten = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showNumnber];
    });

    self->delayStopVideoBlock = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_BARRIER, QOS_CLASS_DEFAULT, 0, ^{
        self.isDetecting = NO;
        [self stopRecord:YES];
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), self->delayStopVideoBlock);

    _recordState = 2;
}

- (void)generateDCTimeStampFilePath {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss-SSS"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [array btd_objectAtIndex:0];
    NSString *videosFolder = [documents stringByAppendingPathComponent:@"videosFolder"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:videosFolder]) {
        [fileMgr createDirectoryAtPath:videosFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    _recordTimeStamp = [videosFolder stringByAppendingPathComponent:dateStr];
}

- (void)stopRecord:(BOOL)canUpload {
    NSLog(@"stop Record ,upload %d", canUpload);
    [self stopNumber];

    self->_mCanUpload = canUpload;
    //等成功停止了才上传
    [_srcVideoRecorder finishWritingWithCompletionHandler:^{
        self->_recordState = 0;
        NSLog(@"finishWritingWithCompletionHandler ,upload %d", self.mCanUpload);
        if (self->_mCanUpload)
            [self upload];
        else {
            //delete video
            NSString *outputFile = [NSString stringWithFormat:@"%@_src.mp4", self->_recordTimeStamp];
            [self deleteVideo:outputFile];
        }
    }];
}

- (void)recordSrcVideo:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (_recordState == 2) {
        BOOL isVideo = ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]);
        [_srcVideoRecorder appendSampleBuffer:sampleBuffer mediaType:(isVideo ? AVMediaTypeVideo : AVMediaTypeAudio)];
    }
}

- (void)showNumnber {
    //4s to show 4 number
    if (self.curNumIndex > self.readNumber.length - 1) {
        self.isDetecting = NO;
        return;
    }
    if (_recordState != 2)
        return;

    NSString *temp = [self.readNumber substringToIndex:self.curNumIndex + 1];
    [self.faceVC.readNumberView updateNumber:temp maxLength:(int)self.readNumber.length];

    self->delayNumberBlock = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_BARRIER, QOS_CLASS_DEFAULT, 0, ^{
        if (self->_recordState == 2) {
            self.curNumIndex++;
            [self showNumnber];
        }
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), self->delayNumberBlock);
}

- (void)stopNumber {
    if (self->delayNumberBlock != nullptr)
        dispatch_block_cancel(self->delayNumberBlock);
    self->delayNumberBlock = nil;
    [self.faceVC.readNumberView updateNumber:@"" maxLength:(int)self.readNumber.length];

    self.curNumIndex = 0;
}

- (void)upload {
    //read video
    NSString *outputFile = [NSString stringWithFormat:@"%@_src.mp4", _recordTimeStamp];

    //upload
    [self.faceVC doUpload:outputFile resultCode:3];
}

- (void)deleteVideo:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:nil];
}

- (void)setMaskRadiusRatio:(float)maskRadiusRadio offsetToCenterRatio:(float)offsetToCenterRatio {
    [_faceliveInstance setMaskRadiusRatio:maskRadiusRadio offsetToCenterRatio:offsetToCenterRatio];
}

@end
