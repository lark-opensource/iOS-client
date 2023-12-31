//
//  VideoRecorder.m
//  smash_demo
//
//  Created by liqing on 2020/2/14.
//

#import "BDCTVideoRecorder.h"
#import "BytedCertManager.h"
#import "BDCTEventTracker.h"
#import <UIKit/UIDevice.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <ByteDanceKit/BTDMacros.h>
#import <BDAlogProtocol/BDAlogProtocol.h>


@interface BDCTVideoRecorder ()
{
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterPixelBufferInput;
    CVPixelBufferRef _pixelBuffer;
    dispatch_queue_t _writingQueue;
}

@property (nonatomic, assign) float outputScale;
@property (nonatomic, assign) BOOL recordAudio;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;

@end


@implementation BDCTVideoRecorder

#pragma mark - init

- (instancetype)initWithOutputURL:(NSURL *)outputURL {
    return [self initWithOutputURL:outputURL outputScale:1.0];
}

- (instancetype)initWithOutputURL:(NSURL *)outputURL outputScale:(float)outputScale {
    return [self initWithOutputURL:outputURL outputScale:outputScale recordAudio:YES];
}

- (instancetype)initWithOutputURL:(NSURL *)outputURL outputScale:(float)outputScale recordAudio:(BOOL)recordAudio {
    self = [super init];
    if (self) {
        NSError *error = nil;
        _assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:(NSString *)kUTTypeMPEG4 error:&error];
        if (error) {
            _assetWriter = nil;
            return nil;
        }
        _outputScale = outputScale;
        _recordAudio = recordAudio;

        _assetWriter.shouldOptimizeForNetworkUse = YES;
        _assetWriter.metadata = [self _metadataArray];

        _writingQueue = dispatch_queue_create("com.bytedance.cert.videorecord.writer", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSURL *)outputURL {
    return _assetWriter.outputURL;
}

#pragma mark - private

- (NSArray *)_metadataArray {
    UIDevice *currentDevice = [UIDevice currentDevice];

    // device model
    AVMutableMetadataItem *modelItem = [[AVMutableMetadataItem alloc] init];
    [modelItem setKeySpace:AVMetadataKeySpaceCommon];
    [modelItem setKey:AVMetadataCommonKeyModel];
    [modelItem setValue:[currentDevice localizedModel]];

    // software
    AVMutableMetadataItem *softwareItem = [[AVMutableMetadataItem alloc] init];
    [softwareItem setKeySpace:AVMetadataKeySpaceCommon];
    [softwareItem setKey:AVMetadataCommonKeySoftware];
    [softwareItem setValue:@"videoRecorder"];

    // creation date
    AVMutableMetadataItem *creationDateItem = [[AVMutableMetadataItem alloc] init];
    [creationDateItem setKeySpace:AVMetadataKeySpaceCommon];
    [creationDateItem setKey:AVMetadataCommonKeyCreationDate];
    [creationDateItem setValue:[BDCTVideoRecorder formattedTimestampStringFromDate:[NSDate date]]];

    return @[ modelItem, softwareItem, creationDateItem ];
}

+ (NSString *)formattedTimestampStringFromDate:(NSDate *)date {
    if (!date)
        return nil;

    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
        [dateFormatter setLocale:[NSLocale autoupdatingCurrentLocale]];
    });
    return [dateFormatter stringFromDate:date];
}

#pragma mark - setup

- (BOOL)p_setupAudioWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    if (!asbd) {
        return NO;
    }
    unsigned int channels = asbd->mChannelsPerFrame;
    double sampleRate = asbd->mSampleRate;
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
    NSData *currentChannelLayoutData = (currentChannelLayout && aclSize > 0) ? [NSData dataWithBytes:currentChannelLayout length:aclSize] : [NSData data];
    NSDictionary *audioCompressionSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                               AVNumberOfChannelsKey : @(channels),
                                               AVSampleRateKey : @(sampleRate),
                                               AVEncoderBitRateKey : @(44100),
                                               AVChannelLayoutKey : currentChannelLayoutData};
    if (!_assetWriterAudioInput && [_assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
        self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        if (_assetWriterAudioInput && [_assetWriter canAddInput:_assetWriterAudioInput]) {
            [_assetWriter addInput:_assetWriterAudioInput];
        }
    } else {
        _assetWriterAudioInput = nil;
    }
    return _assetWriterAudioInput != nil;
}

- (BOOL)p_setupVideoWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    CMVideoDimensions videoDimensions = dimensions;
    videoDimensions.width = videoDimensions.width / _outputScale;
    videoDimensions.height = videoDimensions.height / _outputScale;
    BDALOG_PROTOCOL_INFO_TAG(BytedCertLogTag, @"videoDimensions:%d  %d", videoDimensions.width, videoDimensions.height);

    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CGSize pixelsSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    NSInteger videoBitRate = (pixelsSize.width / _outputScale) * (pixelsSize.height / _outputScale) * 8;
    NSDictionary *compressionSettings = @{AVVideoAverageBitRateKey : @(videoBitRate),
                                          AVVideoMaxKeyFrameIntervalKey : @(30),      // 关键帧最大间隔，1为每个都是关键帧，数值越大压缩率越高
                                          AVVideoExpectedSourceFrameRateKey : @(240), // 无法设置帧率
                                          AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel};
    NSDictionary *videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                    AVVideoWidthKey : @(videoDimensions.width),
                                    AVVideoHeightKey : @(videoDimensions.height),
                                    AVVideoCompressionPropertiesKey : compressionSettings};

    BDALOG_PROTOCOL_INFO_TAG(BytedCertLogTag, @"assetWriter canApplyOutputSettings = %d, _videoBitRate = %ld", [_assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo], (long)videoBitRate);
    if (!_assetWriterVideoInput && [_assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {
        self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        _assetWriterVideoInput.transform = CGAffineTransformIdentity;
        NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, [NSNumber numberWithInt:videoDimensions.width], kCVPixelBufferWidthKey, [NSNumber numberWithInt:videoDimensions.height], kCVPixelBufferHeightKey, nil];
        _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
        if (_assetWriterVideoInput && [_assetWriter canAddInput:_assetWriterVideoInput]) {
            [_assetWriter addInput:_assetWriterVideoInput];
        }
        NSDictionary *options = [NSDictionary dictionary];
        CVPixelBufferCreate(kCFAllocatorDefault, videoDimensions.width, videoDimensions.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)(options), &_pixelBuffer);
    } else {
        self.assetWriterVideoInput = nil;
    }
    return _assetWriterVideoInput != nil;
}

#pragma mark - sample buffer writing

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType {
    CFRetain(sampleBuffer);
    dispatch_async(_writingQueue, ^{
        if ([mediaType isEqualToString:AVMediaTypeAudio] && self.assetWriterAudioInput == nil) {
            [self p_setupAudioWithSampleBuffer:sampleBuffer];
        }
        if ([mediaType isEqualToString:AVMediaTypeVideo] && self.assetWriterVideoInput == nil) {
            [self p_setupVideoWithSampleBuffer:sampleBuffer];
        }
        if (self.assetWriterVideoInput != nil && (self.assetWriterAudioInput != nil || !self.recordAudio)) {
            [self p_appendSampleBuffer:sampleBuffer mediaType:mediaType];
        }
        CFRelease(sampleBuffer);
    });
}

- (void)p_appendSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType {
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    if (_assetWriter.status == AVAssetWriterStatusUnknown && [mediaType isEqualToString:AVMediaTypeVideo]) {
        if ([_assetWriter startWriting]) {
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_assetWriter startSessionAtSourceTime:timestamp];
        } else {
            return;
        }
    }

    if (_assetWriter.status == AVAssetWriterStatusFailed || _assetWriter.status == AVAssetWriterStatusCancelled || _assetWriter.status == AVAssetWriterStatusCompleted) {
        return;
    }

    if (_assetWriter.status == AVAssetWriterStatusWriting) {
        AVAssetWriterInput *input = [mediaType isEqualToString:AVMediaTypeVideo] ? _assetWriterVideoInput : _assetWriterAudioInput;
        if (input.readyForMoreMediaData) {
            [input appendSampleBuffer:sampleBuffer];
        }
    }
}

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler {
    [self finishWritingWithCompletion:^(AVAssetWriterStatus status, NSURL *_Nonnull fileURL, NSError *_Nullable error) {
        if (handler != nil) {
            handler();
        }
    }];
}

- (void)finishWritingWithCompletion:(void (^)(AVAssetWriterStatus, NSURL *_Nonnull, NSError *_Nullable))completion {
    [self p_finishWritingWithCompletion:completion];
}

- (void)p_finishWritingWithCompletion:(void (^)(AVAssetWriterStatus, NSURL *_Nonnull, NSError *_Nullable))completion {
    dispatch_async(_writingQueue, ^{
        if (self.assetWriter.status == AVAssetWriterStatusUnknown ||
            self.assetWriter.status == AVAssetWriterStatusCompleted) {
            BDALOG_PROTOCOL_INFO_TAG(BytedCertLogTag, @"assetWriter can not stop, status = %@, output = %@, error = %@", @(self.assetWriter.status), self.outputURL, self.assetWriter.error);
            [BDCTEventTracker trackWithEvent:@"byted_cert_asset_write_result" params:@{@"result" : @"fail",
                                                                                       @"error" : (self.assetWriter.error.description ?: @"")}];
            if (completion != nil) {
                completion(self.assetWriter.status, self.outputURL, self.assetWriter.error);
            }
            return;
        }
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];

        @weakify(self);
        [self.assetWriter finishWritingWithCompletionHandler:^{
            @strongify(self);
            BDALOG_PROTOCOL_INFO_TAG(BytedCertLogTag, @"assetWriter stop success, status = %@, output = %@, error = %@", @(self.assetWriter.status), self.outputURL, self.assetWriter.error);
            [BDCTEventTracker trackWithEvent:@"byted_cert_asset_write_result" params:@{@"result" : (self.assetWriter.error == nil ? @"success" : @"fail"),
                                                                                       @"error" : (self.assetWriter.error.description ?: @"")}];
            if (completion != nil) {
                completion(self.assetWriter.status, self.outputURL, self.assetWriter.error);
            }
        }];
    });
}

@end
