//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonService.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - KryptonMediaRecorderData

@protocol KryptonMediaRecorderData <NSObject>
- (NSString *)path;
- (CGFloat)duration;
- (NSUInteger)size;
@end

typedef void (^KryptonMediaRecorderStartCallback)(BOOL result);
typedef void (^KryptonMediaRecorderEndCallback)(id<KryptonMediaRecorderData> __nullable result,
                                                NSString *__nullable errMsg);

#pragma mark - KryptonCameraConfig

@protocol KryptonMediaRecorder <NSObject>
- (void)configVideoWithMimeType:(NSString *)mimeType
                       duration:(NSUInteger)duration
                          width:(NSUInteger)width
                         height:(NSUInteger)height
                            bps:(NSUInteger)bps
                            fps:(NSUInteger)fps;
- (void)configAudioWithChanels:(NSUInteger)channels
                           bps:(NSUInteger)bps
                    sampleRate:(NSUInteger)sampleRate;

- (void)startRecordWithStartCallback:(KryptonMediaRecorderStartCallback)startCallback
                         endCallback:(KryptonMediaRecorderEndCallback)endCallback;
- (void)pauseRecord;
- (void)resumeRecord;
- (void)stopRecord;

- (void)onFrameAvailable:(CVPixelBufferRef)ref;
- (void)onAudioSample:(void *)ptr length:(int)samples;

- (uint64_t)lastPresentationTime;
- (void)clipWithTimeRanges:(NSArray<NSNumber *> *)timeRanges
            andEndCallback:(KryptonMediaRecorderEndCallback)endCallback;

- (void)destroy:(BOOL)deleteCachedFiles;
@end

#pragma mark - KryptonMediaRecorderService

@protocol KryptonMediaRecorderService <KryptonService>

- (id<KryptonMediaRecorder>)createMediaRecorder;

@end

NS_ASSUME_NONNULL_END
