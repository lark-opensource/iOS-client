// Copyright 2022 The Lynx Authors. All rights reserved.

#import "KryptonDefaultMediaRecorder.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "LynxThreadManager.h"
#include "canvas/base/log.h"

@implementation KryptonDefaultMediaRecorderService {
  NSString *_temporaryDirectory;
}
- (id<KryptonMediaRecorder>)createMediaRecorder {
  KryptonDefaultMediaRecorder *recorder = [[KryptonDefaultMediaRecorder alloc] init];
  [recorder configRecordFileDirectory:_temporaryDirectory];
  return recorder;
}

- (void)setTemporaryDirectory:(NSString *)directory {
  _temporaryDirectory = directory;
}
@end

@interface KryptonMediaRecorderDataInfoImpl : NSObject <KryptonMediaRecorderData>
@property(strong, nonatomic) NSString *path;
@property(assign, nonatomic) NSUInteger size;
@property(assign, nonatomic) CGFloat duration;
@end

@implementation KryptonMediaRecorderDataInfoImpl
@end

@implementation KryptonDefaultMediaRecorder {
  KryptonMediaRecorderEndCallback _recordEndCallback;
  NSString *_mimeType;
  NSUInteger _maxDuration;
  NSUInteger _videoWidth, _videoHeight, _videoBPS, _videoFPS;
  BOOL _useAudio;
  NSUInteger _audioBPS, _audioSampleRate, _audioChannels;

  AVAssetWriter *_assetWriter;
  AVAssetWriterInput *_videoInput;
  AVAssetWriterInput *_audioInput;
  AVAssetWriterInputPixelBufferAdaptor *_videoBuffer;
  AVURLAsset *_avAsset;
  NSString *_localVideoPath, *_recordFileDirectory;
  NSMutableArray<NSString *> *_cachedPathArray;
  CMAudioFormatDescriptionRef _audioFormat;
  dispatch_queue_t _recordQueue;

  double _duration;
  uint64_t _frameCount, _startTime, _pausedTime, _lastPauseTime, _lastFrameCurrentTime,
      _lastFrameTime;
  uint64_t _totalAudioSamples, _audioTimeOffset, _lastAudioSampleTime;
  BOOL _running, _paused, _isSessionStarted;
}

- (void)configVideoWithMimeType:(NSString *)mimeType
                       duration:(NSUInteger)duration
                          width:(NSUInteger)width
                         height:(NSUInteger)height
                            bps:(NSUInteger)bps
                            fps:(NSUInteger)fps {
  _mimeType = mimeType;
  _maxDuration = duration;
  _videoWidth = width;
  _videoHeight = height;
  _videoBPS = bps;
  _videoFPS = fps;
}

- (void)configAudioWithChanels:(NSUInteger)channels
                           bps:(NSUInteger)bps
                    sampleRate:(NSUInteger)sampleRate {
  if (channels < 0) {
    _useAudio = NO;
    return;
  }

  KRYPTON_LOGI("Recorder has audio");
  _audioChannels = channels;
  _audioBPS = bps;
  _audioSampleRate = sampleRate;
  _audioFormat = nullptr;
  _useAudio = YES;
}

- (void)configRecordFileDirectory:(NSString *)directory {
  _recordFileDirectory = directory;
}

- (uint64_t)lastPresentationTime {
  return _lastFrameTime;
}

- (NSString *)generateTempVideoPath {
  NSString *fileName = [NSString stringWithFormat:@"KRYPTON-%@.mp4", [NSUUID UUID].UUIDString];

  NSString *directory = NSTemporaryDirectory();
  if ([_recordFileDirectory length] > 0) {
    NSString *customDirectory = [_recordFileDirectory stringByExpandingTildeInPath];
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:customDirectory
                                                       isDirectory:&isDir];
    if (exists && isDir) {
      directory = customDirectory;
    }
  }

  NSString *fullPath = [directory stringByAppendingPathComponent:fileName];
  [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];

  KRYPTON_LOGI("Generate temp file for recording " << [fullPath UTF8String]);
  return fullPath;
}

- (void)doStopRecordTask {
  __weak __typeof(self) weakSelf = self;

  [_assetWriter finishWritingWithCompletionHandler:^{
    [weakSelf postWritingWithCompletion];
  }];

  _assetWriter = nil;
  _videoInput = nil;
  _videoBuffer = nil;
  _audioInput = nil;

  if (_useAudio && _audioFormat) {
    CFRelease(_audioFormat);
    _audioFormat = nullptr;
  }
}

- (void)stopRecord {
  if (!_running) {
    return;
  }

  _running = NO;

  __weak __typeof(self) weakSelf = self;
  [self dispatchRecorderTask:^{
    @autoreleasepool {
      [weakSelf doStopRecordTask];
    }
  }];
}

- (void)notifyErrorStop:(NSString *)err {
  KRYPTON_LOGI("Record stoped on error: ") << (err ? [err UTF8String] : "");
  if (_localVideoPath != nil) {
    [self tryToRemoveFile:_localVideoPath];
  }

  if (_recordEndCallback != nullptr) {
    _recordEndCallback(nil, err);
  }
}

- (void)postWritingWithCompletion {
  if (_assetWriter.status == AVAssetWriterStatusFailed) {
    [self notifyErrorStop:@"has write data error"];
    return;
  }

  NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:self->_localVideoPath
                                                                        error:nil];
  uint64_t size = [[dict objectForKey:NSFileSize] unsignedLongLongValue];
  if (size == 0) {
    [self notifyErrorStop:@"result video file empty"];
    return;
  }

  [_cachedPathArray addObject:_localVideoPath];

  if (_recordEndCallback != nullptr) {
    KryptonMediaRecorderDataInfoImpl *data = [[KryptonMediaRecorderDataInfoImpl alloc] init];
    data.size = size;
    data.path = _localVideoPath;
    data.duration = _duration;
    _recordEndCallback(data, nil);
  }

  KRYPTON_LOGI("Record stoped success with video size ") << size;
}

- (void)tryToRemoveFile:(NSString *)path {
  if ([path length] > 0) {
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  }
}

- (void)destroy:(BOOL)deleteCachedFiles {
  _recordEndCallback = nullptr;  // no callbacks

  [self stopRecord];

  if (deleteCachedFiles) {
    if (_cachedPathArray != nil) {
      for (NSString *filePath : _cachedPathArray) {
        [self tryToRemoveFile:filePath];
      }
    }
    KRYPTON_LOGI("Record destroy with video files deleted");
  } else {
    KRYPTON_LOGI("Record destroy with " << [_cachedPathArray count] << " video files not deleted");
  }
}

- (void)dispatchRecorderTask:(dispatch_block_t)runnable {
  DCHECK(runnable);

  if (_recordQueue) {
    dispatch_async(_recordQueue, runnable);
    return;
  }

  NSString *prefix = @"KryptonMediaRecorder";
  [LynxThreadManager createIOSThread:prefix runnable:runnable];
  _recordQueue = [LynxThreadManager getCachedQueueWithPrefix:prefix];
}

- (void)startRecordWithStartCallback:(KryptonMediaRecorderStartCallback)startCallback
                         endCallback:(KryptonMediaRecorderEndCallback)endCallback {
  _recordEndCallback = endCallback;
  _cachedPathArray = [[NSMutableArray alloc] init];
  _frameCount = 0;
  _isSessionStarted = NO;
  _lastFrameCurrentTime = _lastFrameTime = 0;
  _running = NO;
  _localVideoPath = nil;
  _pausedTime = 0;  // to align the timestamp after restoring from the background

  __weak __typeof(self) weakSelf = self;
  [self dispatchRecorderTask:^{
    @autoreleasepool {
      BOOL result = [weakSelf doStartRecordWithEndCallback:endCallback];
      if (startCallback != nullptr) {
        startCallback(result);
      }
    }
  }];
}

- (BOOL)doStartRecordWithEndCallback:(KryptonMediaRecorderEndCallback)endCallback {
  KRYPTON_LOGI("Recorder starting");

  _localVideoPath = [self generateTempVideoPath];

  NSURL *fileUrl = [NSURL fileURLWithPath:_localVideoPath];
  _assetWriter = [AVAssetWriter assetWriterWithURL:fileUrl fileType:AVFileTypeMPEG4 error:nil];

  NSDictionary *video_settings = @{
    AVVideoCodecKey : AVVideoCodecH264,
    AVVideoWidthKey : [NSNumber numberWithUnsignedLong:_videoWidth],
    AVVideoHeightKey : [NSNumber numberWithUnsignedLong:_videoHeight],
    AVVideoCompressionPropertiesKey : @{
      AVVideoExpectedSourceFrameRateKey : [NSNumber numberWithUnsignedLong:_videoFPS],
      AVVideoAverageBitRateKey : [NSNumber numberWithUnsignedLong:_videoBPS],
      AVVideoMaxKeyFrameIntervalKey : [NSNumber numberWithUnsignedLong:12],
    }
  };

  NSDictionary *pixel_buffer_attributes =
      @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
  _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                   outputSettings:video_settings];
  _videoInput.expectsMediaDataInRealTime = YES;
  _videoBuffer = [AVAssetWriterInputPixelBufferAdaptor
      assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput
                                 sourcePixelBufferAttributes:pixel_buffer_attributes];
  [_assetWriter addInput:_videoInput];

  if (_useAudio) {
    [self startAudio];
  }

  // MUST start AssetWriter before create pixelBufferPool
  if (![_assetWriter startWriting]) {
    KRYPTON_LOGE("Recorder start error: open file failed, status:")
        << _assetWriter.status << ", error:" << _assetWriter.error;
    return NO;
  }

  _running = YES;
  _paused = NO;

  KRYPTON_LOGI("Recorder started");
  return YES;
}

- (void)pauseRecord {
  KRYPTON_LOGI("Recorder paused");
  _lastPauseTime = [self getMicroSecondTime];
  _paused = YES;
}

- (void)resumeRecord {
  KRYPTON_LOGI("Recorder resume");
  _pausedTime = _pausedTime + [self getMicroSecondTime] - _lastPauseTime;
  _paused = NO;
}

- (uint64_t)getMicroSecondTime {
  struct timespec currTime;
  if (@available(iOS 10.0, *)) {
    clock_gettime(CLOCK_MONOTONIC, &currTime);
  } else {
    // Fallback on earlier versions
  }
  return currTime.tv_sec * 1000000LLU + currTime.tv_nsec / 1000LLU;
}

- (void)onFrameAvailable:(CVPixelBufferRef)ref {
  if (_running == NO || _paused || !_videoInput.readyForMoreMediaData) {
    // ignore frames
    return;
  }

  uint64_t currentTime = [self getMicroSecondTime];
  if (_useAudio) {
    if (_totalAudioSamples == 0) {
      // no audio samples, time stamp is not updated, so startTime or appendPixelBuffer is forbiden
      return;
    }

    if (currentTime - _lastAudioSampleTime > 30000) {  // 30ms
      // audio may be breaked, ignore related videos
      return;
    }
  }

  if (++_frameCount <= 1) {
    // ignore first frame to prevent dark screen
    return;
  }

  if (!_isSessionStarted) {
    _startTime = currentTime - (_useAudio ? _audioTimeOffset : 0);
    [_assetWriter startSessionAtSourceTime:CMTimeMake(0, 1000000)];
    _isSessionStarted = YES;
  }

  static const uint64_t minInterval = 8000;
  if (currentTime - _lastFrameCurrentTime < minInterval) {
    // Frame interval is less than 8ms, do not submit
    return;
  }

  _lastFrameCurrentTime = currentTime;

  const uint64_t frameTime =
      currentTime - (_useAudio ? _audioTimeOffset : _startTime + _pausedTime);
  if (_frameCount > 2 && frameTime - _duration * 1e6 < minInterval) {
    return;
  }

  _lastFrameTime = frameTime;
  _duration = frameTime / 1e6;
  if (_maxDuration > 0 && _duration > _maxDuration) {
    [self stopRecord];
    return;
  }

  @try {
    BOOL ret = [_videoBuffer appendPixelBuffer:ref
                          withPresentationTime:CMTimeMake(frameTime, 1000000)];
    if (!ret) {
      KRYPTON_LOGW("Append pixelbuffer failed");
    }
  } @catch (NSException *exception) {
    KRYPTON_LOGW("Append pixelbuffer exception");
  }
}

- (void)startAudio {
  _totalAudioSamples = 0;
  _audioTimeOffset = _lastAudioSampleTime = -1;

  [self initAudioFormat];

  AudioChannelLayout acl;
  memset(&acl, 0, sizeof(acl));
  acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
  NSDictionary *audioSettings = @{
    AVFormatIDKey : @(kAudioFormatMPEG4AAC),
    AVSampleRateKey : [NSNumber numberWithUnsignedLong:_audioSampleRate],
    AVNumberOfChannelsKey : [NSNumber numberWithUnsignedLong:_audioChannels],
    AVEncoderBitRateKey : [NSNumber numberWithUnsignedLong:_audioBPS],
    AVChannelLayoutKey : [NSData dataWithBytes:&acl length:sizeof(acl)]
  };
  _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                   outputSettings:audioSettings];
  _audioInput.expectsMediaDataInRealTime = NO;
  [_assetWriter addInput:_audioInput];
}

- (void)initAudioFormat {
  AudioStreamBasicDescription asbd;
  asbd.mSampleRate = _audioSampleRate;
  asbd.mFormatID = kAudioFormatLinearPCM;
  asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  asbd.mBytesPerPacket = 4;
  asbd.mFramesPerPacket = 1;
  asbd.mBytesPerFrame = 4;
  asbd.mChannelsPerFrame = UInt32(_audioChannels);
  asbd.mBitsPerChannel = 16;
  asbd.mReserved = 0;
  CMAudioFormatDescriptionCreate(nullptr, &asbd, 0, nullptr, 0, nullptr, nullptr, &_audioFormat);
}

- (void)onAudioSample:(void *)ptr length:(int)samples {
  if (!_running || !_useAudio || _audioFormat == nullptr) {
    return;
  }

  if (ptr == 0 || samples <= 0) {
    return;
  }

  _lastAudioSampleTime = [self getMicroSecondTime];
  _totalAudioSamples += samples;
  _audioTimeOffset = _lastAudioSampleTime - (_totalAudioSamples * 1e6 / _audioSampleRate);

  if (!_isSessionStarted || _paused || _assetWriter.status != AVAssetWriterStatusWriting ||
      ![_audioInput isReadyForMoreMediaData]) {
    // KRYPTON_LOGV("Drop audio samples");
    return;
  }

  CMBlockBufferRef block = nullptr;
  size_t sampleSize = samples << 2;

  // audio time is based from video frist frame
  CMTime targetTime = CMTimeSubtract(CMTimeMake(_totalAudioSamples, (int32_t)_audioSampleRate),
                                     CMTimeMake(_startTime, 1e6));

  CMBlockBufferCreateWithMemoryBlock(nullptr, ptr, sampleSize, kCFAllocatorNull, nullptr, 0,
                                     sampleSize, 0, &block);
  if (block) {
    __weak __typeof(self) weakSelf = self;
    [self dispatchRecorderTask:^{
      @autoreleasepool {
        [weakSelf doAddAudioSampleTask:block samples:samples targetTime:targetTime];
      }
    }];
  }
}

- (void)doAddAudioSampleTask:(CMBlockBufferRef)block
                     samples:(int)samples
                  targetTime:(CMTime)targetTime {
  if (!_running) {
    return;
  }

  DCHECK(block);

  CMSampleBufferRef sample = nullptr;
  @try {
    CMAudioSampleBufferCreateReadyWithPacketDescriptions(nullptr, block, _audioFormat, samples,
                                                         targetTime, nullptr, &sample);
    if (!sample || ![_audioInput appendSampleBuffer:sample]) {
      KRYPTON_LOGW("Audio Sample Write Failed ");
    }
  } @catch (NSException *exception) {
    KRYPTON_LOGW("Audio Sample Write exception");
  }

  if (sample) {
    CFRelease(sample);
  }

  CFRelease(block);
}

- (void)clipVideoSuccessWithPath:(NSString *)path {
  KRYPTON_LOGW("clip success with path");
}

- (void)clipWithTimeRanges:(NSArray<NSNumber *> *)timeRanges
            andEndCallback:(KryptonMediaRecorderEndCallback)endCallback {
  if (timeRanges == nil || timeRanges.count < 2) {
    [self notifyClipErrorEndWithCallback:endCallback path:nil error:@"no time range"];
    return;
  }

  NSString *destVideoPath = [self generateTempVideoPath];
  @try {
    NSDictionary *options =
        [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                    forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:_localVideoPath]
                                             options:options];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack =
        [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                 preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray<AVAssetTrack *> *videoTacks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTacks.count == 0) {
      [self notifyClipErrorEndWithCallback:endCallback path:destVideoPath error:@"no video track"];
      return;
    }

    AVAssetTrack *videoTrack = videoTacks[0], *audioTrack = nil;
    ;
    CMTime totalDuration = kCMTimeZero;
    uint64_t durationUs = 0;
    AVMutableCompositionTrack *compositionAudioTrack = nil;
    NSArray<AVAssetTrack *> *audioTacks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTacks.count > 0) {
      compositionAudioTrack =
          [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                   preferredTrackID:kCMPersistentTrackID_Invalid];
      audioTrack = audioTacks[0];
    }

    for (NSUInteger i = 1; i < timeRanges.count; i += 2) {
      uint64_t start = [timeRanges[i - 1] unsignedLongLongValue];
      uint64_t end = [timeRanges[i] unsignedLongLongValue];
      if (end <= start) {
        continue;
      }

      durationUs += end - start;
      CMTimeRange itemRange;
      itemRange.start = CMTimeMake(start, 1e6);
      itemRange.duration = CMTimeSubtract(CMTimeMake(end, 1e6), itemRange.start);

      CMTimeRange itemVideoRange = CMTimeRangeGetIntersection(itemRange, videoTrack.timeRange);
      [compositionVideoTrack insertTimeRange:itemVideoRange
                                     ofTrack:videoTrack
                                      atTime:totalDuration
                                       error:nil];

      if (compositionAudioTrack != nil) {
        CMTimeRange itemAudioRange = CMTimeRangeGetIntersection(itemRange, audioTrack.timeRange);
        [compositionAudioTrack insertTimeRange:itemAudioRange
                                       ofTrack:audioTrack
                                        atTime:totalDuration
                                         error:nil];
      }
      totalDuration = CMTimeAdd(totalDuration, itemVideoRange.duration);
    }

    AVAssetExportSession *exporterSession =
        [[AVAssetExportSession alloc] initWithAsset:composition
                                         presetName:AVAssetExportPresetHighestQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.outputURL = [NSURL fileURLWithPath:destVideoPath];
    exporterSession.shouldOptimizeForNetworkUse = YES;

    __weak __typeof(self) weakSelf = self;
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
      [weakSelf postClipWithCallback:endCallback
                                path:destVideoPath
                              status:exporterSession.status
                          durationUs:durationUs];
    }];

  } @catch (NSException *exception) {
    [self notifyClipErrorEndWithCallback:endCallback
                                    path:destVideoPath
                                   error:@"clip video exception"];
  }
}

- (void)notifyClipErrorEndWithCallback:(KryptonMediaRecorderEndCallback)callback
                                  path:(NSString *)path
                                 error:(NSString *)err {
  KRYPTON_LOGW("Record clip end with error: ") << (err ? [err UTF8String] : "");

  if (path != nil) {
    [self tryToRemoveFile:path];
  }

  if (callback != nullptr) {
    callback(nil, err);
  }
}

- (void)postClipWithCallback:(KryptonMediaRecorderEndCallback)callback
                        path:(NSString *)path
                      status:(AVAssetExportSessionStatus)status
                  durationUs:(uint64_t)durationUs {
  switch (status) {
    case AVAssetExportSessionStatusUnknown:
      KRYPTON_LOGI("record clip exporter unknow");
      break;
    case AVAssetExportSessionStatusCancelled:
      KRYPTON_LOGI("record clip exporter canceled");
      break;
    case AVAssetExportSessionStatusFailed:
      KRYPTON_LOGI("record clip exporter failed");
      [self notifyClipErrorEndWithCallback:callback path:path error:@"record clip exporter failed"];
      break;
    case AVAssetExportSessionStatusWaiting:
      KRYPTON_LOGI("record clip exporter waiting");
      break;
    case AVAssetExportSessionStatusExporting:
      KRYPTON_LOGI("record clip exporter exporting");
      break;
    case AVAssetExportSessionStatusCompleted:
      KRYPTON_LOGI("record clip exporter completed");
      {
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        uint64_t size = [[dict objectForKey:NSFileSize] unsignedLongLongValue];
        if (size == 0) {
          [self notifyClipErrorEndWithCallback:callback
                                          path:path
                                         error:@"record clip result file empty"];
          return;
        }

        [_cachedPathArray addObject:path];

        if (callback != nullptr) {
          KryptonMediaRecorderDataInfoImpl *data = [[KryptonMediaRecorderDataInfoImpl alloc] init];
          data.size = size;
          data.path = path;
          data.duration = 1.0f * durationUs / 1e6;
          callback(data, nil);
        }
        KRYPTON_LOGI("Record clip success with video size ") << size;
      }
      break;
  }
}

@end
