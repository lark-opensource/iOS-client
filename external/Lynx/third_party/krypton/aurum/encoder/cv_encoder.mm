// Copyright 2022 The Lynx Authors. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#include "aurum/config.h"
#include "aurum/encoder.h"
#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace au {

class CVEncoder : public EncoderBase {
 public:
  bool Init(const char *path) {
    ::unlink(path);

    NSURL *file_url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path]];
    asset_writer_ = [AVAssetWriter assetWriterWithURL:file_url fileType:AVFileTypeMPEG4 error:nil];

    // Audio
    // Setup Audio Stream
    AudioChannelLayout acl;
    memset(&acl, 0, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *audioSettings = @{
      AVFormatIDKey : @(kAudioFormatMPEG4AAC),  // aac format
      AVSampleRateKey : @(AU_SAMPLE_RATE),      //
      AVNumberOfChannelsKey : @(2),             // double channel
      AVEncoderBitRateKey : @(128 * 1024),      // 128kbps
      AVChannelLayoutKey : [NSData dataWithBytes:&acl length:sizeof(acl)]
    };

    audio_input_ = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                      outputSettings:audioSettings];
    audio_input_.expectsMediaDataInRealTime = NO;
    [asset_writer_ addInput:audio_input_];

    if (![asset_writer_ startWriting]) {
      KRYPTON_LOGW("cannot open file for write: status= ")
          << (long)asset_writer_.status
          << " error= " << [asset_writer_.error.description UTF8String];
      return NO;
    }
    [asset_writer_ startSessionAtSourceTime:CMTimeMake(0, 1000000)];

    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = AU_SAMPLE_RATE;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBytesPerPacket = 4;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 4;
    asbd.mChannelsPerFrame = 2;
    asbd.mBitsPerChannel = 16;
    asbd.mReserved = 0;

    CMAudioFormatDescriptionCreate(nullptr, &asbd, 0, nullptr, 0, nullptr, nullptr, &format_);

    return YES;
  }

  virtual void Write(Sample sample) override {
    if (asset_writer_.status != AVAssetWriterStatusWriting ||
        !audio_input_.isReadyForMoreMediaData) {  // dropped sample
      return;
    }

    CMBlockBufferRef block_buf = nullptr;
    CMSampleBufferRef sample_buf = nullptr;

    size_t sample_size = sample.length << 2;

    int32_t *ptr = buffer_[next_sample_++ & 3];
    memcpy(ptr, sample.data, sample_size);

    CMBlockBufferCreateWithMemoryBlock(nullptr, ptr, sample_size, kCFAllocatorNull, nullptr, 0,
                                       sample_size, 0, &block_buf);
    CMAudioSampleBufferCreateReadyWithPacketDescriptions(nullptr, block_buf, format_, sample.length,
                                                         CMTimeMake(total_samples_, AU_SAMPLE_RATE),
                                                         nullptr, &sample_buf);

    if (![audio_input_ appendSampleBuffer:sample_buf]) {
      KRYPTON_LOGW("v_encoder : Audio Sample Write Failed ")
          << [asset_writer_.error.description UTF8String];
    }
    CFRelease(block_buf);
    CFRelease(sample_buf);

    total_samples_ += sample.length;
  }

  virtual ~CVEncoder() {
    NSLock *lock = [[NSLock alloc] init];
    [lock lock];

    [asset_writer_ finishWritingWithCompletionHandler:^{
      KRYPTON_LOGI("finish writing");
      [lock unlock];
    }];
    // wait for writing finished
    [lock lock];
  }

 private:
  AVAssetWriter *asset_writer_;
  AVAssetWriterInput *audio_input_;
  int32_t buffer_[8][512];
  int next_sample_ = 0;
  int total_samples_ = 0;
  CMAudioFormatDescriptionRef format_;
};

EncoderBase *encoder::Mp4aAac(const char *path) {
  CVEncoder *encoder = new CVEncoder();
  if (encoder->Init(path)) {
    return encoder;
  }
  delete encoder;
  return nullptr;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
