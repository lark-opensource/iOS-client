//
//  BDCTDebugManager.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/16.
//

#import "BDCTDebugManager.h"
#import "FaceLiveViewController.h"
#import "FaceLiveViewController+Layout.h"
#import "BDCTFlow.h"
#import "BDCTVideoRecordPreviewViewController.h"
#import "BytedCertManager+Private.h"
#import "BDCTImageManager.h"
#import "BytedCertManager+AliyunPrivate.h"
#import "BDCTWebViewController.h"
#import "BytedCertNFCReader.h"
#import "FaceLiveModule.h"
#import "ActionLivenessTC.h"
#import "LivenessTaskController.h"
#import "AVCaptureSession+BDCTAdditions.h"
#import "FaceLiveDebugViewController.h"

#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import "UIApplication+BDCTAdditions.h"
#include <chrono>


@implementation NSString (BDCTDebugAdditions)

- (void)bdctdebug_displayInSheetViewController {
    UIAlertController *sheetController = [UIAlertController alertControllerWithTitle:nil message:self preferredStyle:(UIDevice.btd_isPadDevice ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];
    [sheetController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:nil]];
    [BTDResponder.topViewController presentViewController:sheetController animated:YES completion:nil];
}

@end


@implementation BytedCertManager (OCRDebug)

@dynamic imageManager;

+ (NSData *)imageWithType:(NSString *)type {
    return [[[self shareInstance] imageManager] getImageByType:type];
}

@end


@interface BDCTDebugManager () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, BDCTFaceLiveViewControllerDelegate>

@property (nonatomic, strong) AVAssetImageGenerator *assertGenerator;
@property (nonatomic, assign) float videoLimit;

@end


@implementation BDCTDebugManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BDCTDebugManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [BDCTDebugManager new];
    });
    return manager;
}

- (NSDictionary *)liveDetectAlgoParamsWithBeauty:(int)beauty {
    return [self liveDetectAlgoParamsWithBeauty:beauty motionType:nil];
}

- (UIImagePickerController *)picker {
    if (!_picker) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        _picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
        _picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        _picker.delegate = self;
    }
    return _picker;
}

- (NSDictionary *)liveDetectAlgoParamsWithBeauty:(int)beauty motionType:(nullable NSString *)motions {
    return @{
        @"liveness_timeout" : @10,
        @"motion_types" : motions ?: @"3,4",
        @"version" : @"1.0",
        @"beauty_intensity" : @(beauty),
        @"liveness_conf" : @[
            @{
                @"enum" : @13,
                @"name" : @"action_liveness_still_liveness_thresh",
                @"value" : @-1.1
            },
            @{
                @"enum" : @14,
                @"name" : @"action_liveness_face_similarity_thresh",
                @"value" : @0.6
            }
        ],
        @"liveness_type" : BytedCertLiveTypeAction,
        @"log_mode" : @YES,
        @"security_mode" : @YES
    };
}

- (void)debugFaceLiveViewController:(NSString *)livenessType {
    [self debugFaceLiveViewController:livenessType motions:nil beauty:0 completion:nil];
}

- (void)debugFaceLiveViewController:(NSString *)livenessType motions:(NSString *_Nullable)motions beauty:(int)beauty completion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:[[BytedCertParameter alloc] init]];
    context.liveDetectRequestParams = @{
        @"liveness_type" : livenessType
    };
    context.backendDecision = @{
        @"live_detect_optimize" : @"all"
    };
    context.finalLivenessType = livenessType;
    BDCTFaceVerificationFlow *flow = [[BDCTFaceVerificationFlow alloc] initWithContext:context];
    FaceLiveViewController *faceliveViewController = [[FaceLiveViewController alloc] initWithFlow:flow liveDetectAlgoParams:[self liveDetectAlgoParamsWithBeauty:beauty motionType:motions]];
    faceliveViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    faceliveViewController.modalPresentationCapturesStatusBarAppearance = YES;
    faceliveViewController.delegate = self;
    [faceliveViewController setCompletionBlock:^(NSDictionary *_Nullable liveDetectResultJson, BytedCertError *_Nullable liveDetectError) {
        if (liveDetectError != nil) {
            [liveDetectError.description bdctdebug_displayInSheetViewController];
        } else {
            [[liveDetectResultJson description] bdctdebug_displayInSheetViewController];
        }
    }];
    [flow showViewController:faceliveViewController];
}

- (void)debugFaceLiveViewController:(NSString *)livenessType completion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置美颜参数" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
        textField.placeholder = @"设置美颜参数（0-100）";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                         int beauty = [alertController.textFields.firstObject.text intValue];

                         BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:[[BytedCertParameter alloc] init]];
                         context.liveDetectRequestParams = @{
                             @"liveness_type" : livenessType
                         };
                         context.finalLivenessType = livenessType;
                         BDCTFaceVerificationFlow *flow = [[BDCTFaceVerificationFlow alloc] initWithContext:context];
                         FaceLiveViewController *faceliveViewController = [[FaceLiveViewController alloc] initWithFlow:flow liveDetectAlgoParams:[self liveDetectAlgoParamsWithBeauty:beauty]];
                         faceliveViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
                         faceliveViewController.modalPresentationCapturesStatusBarAppearance = YES;
                         faceliveViewController.delegate = self;
                         [faceliveViewController setCompletionBlock:^(NSDictionary *_Nullable liveDetectResultJson, BytedCertError *_Nullable liveDetectError) {
                             if (liveDetectError != nil) {
                                 [liveDetectError.description bdctdebug_displayInSheetViewController];
                             } else {
                                 [[liveDetectResultJson description] bdctdebug_displayInSheetViewController];
                             }
                         }];
                         [flow showViewController:faceliveViewController];
                     }]];
    [BTDResponder.topViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)faceViewController:(nonnull FaceLiveViewController *)faceViewController faceCompareWithPackedParams:(nonnull NSDictionary *)packedParams faceData:(nonnull NSData *)faceData resultCode:(int)resultCode completion:(nonnull void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(nil, nil);
    });
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //
    //    });
}

- (void)faceViewController:(nonnull FaceLiveViewController *)faceViewController retryDesicionWithCompletion:(nonnull void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, nil);
    });
}

- (void)debugVideoPlay {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.allowsEditing = NO;
    pickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    pickerController.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [BTDResponder.topViewController.navigationController presentViewController:pickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    if (picker == self.picker) {
        BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:[[BytedCertParameter alloc] init]];
        context.liveDetectRequestParams = @{
            @"liveness_type" : @"motion"
        };
        context.finalLivenessType = @"motion";
        BDCTFaceVerificationFlow *flow = [[BDCTFaceVerificationFlow alloc] initWithContext:context];
        FaceLiveDebugViewController *faceliveViewController = [[FaceLiveDebugViewController alloc] initWithFlow:flow liveDetectAlgoParams:[self liveDetectAlgoParamsWithBeauty:0 motionType:@"0"]];
        faceliveViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        faceliveViewController.modalPresentationCapturesStatusBarAppearance = YES;
        faceliveViewController.delegate = self;
        [faceliveViewController setCompletionBlock:^(NSDictionary *_Nullable liveDetectResultJson, BytedCertError *_Nullable liveDetectError) {
            if (liveDetectError != nil) {
                [liveDetectError.description bdctdebug_displayInSheetViewController];
            } else {
                [@"活体成功" bdctdebug_displayInSheetViewController];
            }
        }];
        [flow showViewController:faceliveViewController];
        [self initAssetGeneratorFromURL:videoURL Size:CGSizeMake(640, 480)];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            float video_start_time = [self currentTime];
            float clock = 0;
            while (clock < self->_videoLimit) {
                UIImage *videoOutput;
                @autoreleasepool {
                    clock = [self currentTime] - video_start_time;

                    NSLog(@"clock : %f ", clock);
                    videoOutput = [self grapFrameForVideo:self->_assertGenerator atTime:clock];

                    if (videoOutput == nil) {
                        NSLog(@"reach video end");
                        break;
                    }
                    CVPixelBufferRef pixels = [self pixelBufferFasterFromCGImage:videoOutput];
                    [faceliveViewController.livenessTC doFaceLive:pixels orient:kClockwiseRotate_0];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [faceliveViewController layoutPreviewIfNeededWithPixelBufferSize:CGSizeMake(CVPixelBufferGetWidth(pixels), CVPixelBufferGetHeight(pixels))];
                        [faceliveViewController.captureRenderView update:pixels];
                    });
                }
            }
        });
    } else {
        [self debugVideoPlayWithURL:videoURL];
    }
}

- (void)initAssetGeneratorFromURL:(NSURL *)url Size:(CGSize)size {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];

    CMTime time = [asset duration];
    _videoLimit = ceil(time.value / time.timescale);

    NSParameterAssert(asset);
    _assertGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];

    if (size.height != 0) {
        _assertGenerator.maximumSize = size;
    }

    _assertGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    _assertGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    _assertGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    _assertGenerator.appliesPreferredTrackTransform = YES;
}

- (float)currentTime {
    using namespace std::chrono;
    milliseconds clock_ms = duration_cast<milliseconds>(high_resolution_clock::now().time_since_epoch());
    return (clock_ms.count() / 1000.0);
}

- (UIImage *)grapFrameForVideo:(AVAssetImageGenerator *)assetImageGenerator atTime:(NSTimeInterval)time {
    CGImageRef singleFrameImageRef = NULL;

    int64_t frame = (int64_t)(time * 600);
    NSError *imageGenerationError = nil;
    singleFrameImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(frame, 600)
                                                      actualTime:NULL
                                                           error:&imageGenerationError];
    if (!singleFrameImageRef) {
        NSLog(@"imageGenerationError %@", imageGenerationError);
    }

    UIImage *singleFrameImage = singleFrameImageRef ? [[UIImage alloc] initWithCGImage:singleFrameImageRef] : nil;

    CGImageRelease(singleFrameImageRef);

    return singleFrameImage;
}

- (CVPixelBufferRef)pixelBufferFasterFromCGImage:(UIImage *)image {
    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                              [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                              nil];

    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(image.CGImage);

    CFDataRef dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    GLubyte *imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, imageData, bytesPerRow, NULL, NULL, (__bridge CFDictionaryRef)options, &pxbuffer);
    CFRelease(dataFromImageDataProvider);
    CVPixelBufferRetain(pxbuffer);
    return pxbuffer;
}

- (void)debugVideoPlayWithURL:(NSURL *)videoURL {
    BDCTVideoRecordPreviewViewController *viewController = [BDCTVideoRecordPreviewViewController new];
    viewController.videoURL = videoURL;
    [BTDResponder.topViewController.navigationController pushViewController:viewController animated:YES];
}

- (void)debugAliyunFaceLive {
}

- (void)debugNFC {
    BytedCertNFCReader *nfcReader = [[BytedCertNFCReader alloc] init];
    NSMutableDictionary *nfcParams = [NSMutableDictionary new];
    nfcParams[@"type"] = @"id_card";
    nfcParams[@"retryTimes"] = @(3);
    nfcParams[@"timeout"] = @(15);
    [nfcReader startNFCWithParams:nfcParams connectBlock:nil completion:^(NSDictionary *_Nonnull nfcResult) {
        if (nfcResult) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:nfcResult options:0 error:&error];
            NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            UIAlertController *alerController = [UIAlertController alertControllerWithTitle:nil message:dataStr preferredStyle:UIAlertControllerStyleAlert];
            [alerController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action){

                                      }]];
            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alerController animated:YES completion:nil];
        }
    }];
}

- (void)debugProtocolUrl {
    [BTDResponder.topViewController.navigationController pushViewController:[[BDCTWebViewController alloc] initWithUrl:@"https://bcy.net/static/privacy" title:nil] animated:YES];
}

- (void)debugActionLivenessWithVideo {
    [UIApplication bdct_requestAlbumPermissionWithSuccessBlock:^{
        [BTDResponder.topViewController.navigationController presentViewController:self.picker animated:YES completion:nil];
    } failBlock:^{

    }];
}

@end
