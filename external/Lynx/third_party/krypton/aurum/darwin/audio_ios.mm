// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/darwin/audio_ios.h"
#import <AudioToolbox/AudioToolbox.h>
#include "aurum/audio_engine.h"

#if TARGET_OS_IPHONE
#import <AVFoundation/AVFoundation.h>

@interface LynxAurumInterruptionListener : NSObject

@property(nonatomic) lynx::canvas::au::AudioIOS *backend;

- (id)init:(lynx::canvas::au::AudioIOS *)backend;
- (void)onAudioInterrupt:(NSNotification *)notification;
- (void)onAppDidBecomeActive:(UIApplication *)application;
- (void)onAudioSessionReset;
@end

#endif

namespace lynx {
namespace canvas {
namespace au {

static OSStatus OutputCallback(void *in_ref_con, AudioUnitRenderActionFlags *io_action_flags,
                               const AudioTimeStamp *in_time_stamp, UInt32 in_bus_number,
                               UInt32 in_number_frames, AudioBufferList *buffers) {
  auto ctx = reinterpret_cast<SampleCallbackContext *>(in_ref_con);
  DCHECK(ctx != nullptr);
  if (ctx->released) {
    KRYPTON_LOGE("iOS audio impl has been released.");
    return 0;
  }

  std::lock_guard<std::mutex> lock(ctx->working_lock);
  if (ctx->released) {
    KRYPTON_LOGE("iOS audio impl has been released.");
    return 0;
  }

  auto backend = reinterpret_cast<AudioIOS *>(ctx->audio_impl);

  AudioBuffer &buf = buffers[0].mBuffers[0];
  short *curr = reinterpret_cast<short *>(buf.mData);

  for (int samples = buf.mDataByteSize >> 2, red = 0; red < samples;) {
    int len = samples - red;
    len = AU_MIN(AU_PLAYBACK_BUF_LEN, len);

    Sample output = backend->GetAudioEngine()->Consume(len);
    if (output.length) {
      memcpy(curr, output.data, len << 2);
    }
    // Data length is insufficient, fill in zero
    if (output.length < len) {
      memset(curr + (output.length << 1), 0, (len - output.length) << 2);
    }
    red += len;
    curr += len << 1;
  }

  return 0;
}

void AudioIOS::OnInitError() { AddInterruptionListener(); }

void AudioIOS::AddInterruptionListener() {
#if TARGET_OS_IPHONE
  interruption_listener_ = [[LynxAurumInterruptionListener alloc] init:this];
  [[NSNotificationCenter defaultCenter] addObserver:interruption_listener_
                                           selector:@selector(onAudioInterrupt:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:interruption_listener_
                                           selector:@selector(onAppDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:interruption_listener_
                                           selector:@selector(onAudioSessionReset)
                                               name:AVAudioSessionMediaServicesWereResetNotification
                                             object:nil];
#endif
}

void AudioIOS::RemoveInterruptionListener() {
#if TARGET_OS_IPHONE
  ((LynxAurumInterruptionListener *)interruption_listener_).backend = nullptr;
  @try {
    [[NSNotificationCenter defaultCenter] removeObserver:interruption_listener_];
  } @catch (NSException *exception) {
  }
  interruption_listener_ = nil;
#endif
}

void AudioIOS::RetryInit() {
  audio_engine_->RunAfterLockSync([backend = this](auto *audio_engine) {
    if (backend->GetAudioUnit() != 0) {
      // check again after lock
      KRYPTON_LOGI("do not need to retry init");
      return true;
    }

    backend->RemoveInterruptionListener();

    auto ret = backend->Init(audio_engine);
    if (ret.code != 0) {
      KRYPTON_LOGI("retry init failed: code = ") << ret.code << ", line = " << ret.line;
      return false;
    } else {
      audio_engine->ForceSetRunning(true);
      KRYPTON_LOGI("retry init success");
      return true;
    }
  });
}

Status AudioIOS::Init(AudioEngine *audio_engine_ptr) {
  audio_engine_ = audio_engine_ptr;

  auto sample_callback_context = new SampleCallbackContext();
  audio_engine_->BindSampleCallbackContext(sample_callback_context);

  AudioComponentDescription desc;
  desc.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
  desc.componentSubType = kAudioUnitSubType_RemoteIO;
#else
  desc.componentSubType = kAudioUnitSubType_DefaultOutput;
#endif
  desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;
  AudioComponent comp = AudioComponentFindNext(nullptr, &desc);

  if (!comp) {
    KRYPTON_LOGE("AudioIOS::Init error: AudioComponentFindNext error");
    OnInitError();
    return AU_ERROR(1);
  }

  AudioUnit audio_unit = 0;
  if (OSStatus ret = AudioComponentInstanceNew(comp, &audio_unit)) {
    KRYPTON_LOGE("AudioIOS::Init error: AudioComponentInstanceNew error ") << ret;
    OnInitError();
    return AU_ERROR(ret);
  }

  AudioStreamBasicDescription streamDescription = {
      .mSampleRate = AU_SAMPLE_RATE,
      .mFormatID = kAudioFormatLinearPCM,
      .mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
      .mFramesPerPacket = 1,
      .mChannelsPerFrame = 2,
      .mBitsPerChannel = sizeof(int16_t) * 8,
      .mBytesPerPacket = 2 * sizeof(int16_t),
      .mBytesPerFrame = 2 * sizeof(int16_t),
  };

  if (OSStatus ret =
          AudioUnitSetProperty(audio_unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                               0, &streamDescription, sizeof(streamDescription))) {
    AudioComponentInstanceDispose(audio_unit);
    KRYPTON_LOGE("AudioIOS::Init error: AudioUnitSetProperty error ") << ret;
    OnInitError();
    return AU_ERROR(ret);
  }

  if (OSStatus ret = AudioUnitInitialize(audio_unit)) {
    KRYPTON_LOGE("AudioIOS::Init error: AudioUnitInitialize error ") << ret;
    AudioComponentInstanceDispose(audio_unit);
    OnInitError();
    return AU_ERROR(ret);
  }

  AURenderCallbackStruct render_callback;
  render_callback.inputProc = OutputCallback;
  render_callback.inputProcRefCon = sample_callback_context;

  AudioUnitSetProperty(audio_unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                       &render_callback, sizeof(render_callback));

  audio_unit_ = audio_unit;
  Resume();

  AddInterruptionListener();

  return AU_OK;
}

void AudioIOS::OnCaptureStart() {
  recording_ = true;
#if TARGET_OS_IPHONE
  AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
  if (@available(iOS 10.0, *)) {
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord
                     withOptions:AVAudioSessionCategoryOptionMixWithOthers |
                                 AVAudioSessionCategoryOptionDefaultToSpeaker |
                                 AVAudioSessionCategoryOptionAllowBluetoothA2DP

                           error:nil];
  }
#endif
}

void AudioIOS::OnCaptureStop() {
  recording_ = false;
#if TARGET_OS_IPHONE
  AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
  [sessionInstance setCategory:AVAudioSessionCategoryPlayback
                   withOptions:AVAudioSessionCategoryOptionMixWithOthers
                         error:nil];

#endif
}

void AudioIOS::Resume() {
#if TARGET_OS_IPHONE
  // Restore AVAudioSession state
  AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
  if (@available(iOS 10.0, *)) {
    [sessionInstance setCategory:recording_ ? AVAudioSessionCategoryPlayAndRecord
                                            : AVAudioSessionCategoryPlayback
                     withOptions:!recording_ ? AVAudioSessionCategoryOptionMixWithOthers
                                             : AVAudioSessionCategoryOptionMixWithOthers |
                                                   AVAudioSessionCategoryOptionDefaultToSpeaker |
                                                   AVAudioSessionCategoryOptionAllowBluetoothA2DP
                           error:nil];
  }

  NSTimeInterval bufferDuration = .01;
  [sessionInstance setPreferredIOBufferDuration:bufferDuration error:nil];

  [sessionInstance setPreferredSampleRate:AU_SAMPLE_RATE error:nil];

  // activate the audio session
  [sessionInstance setActive:YES error:nil];
#endif

  paused_ = false;
  AudioOutputUnitStart(audio_unit_);
}

AudioIOS::~AudioIOS() {
  RemoveInterruptionListener();
  if (audio_unit_) {
    AudioOutputUnitStop(audio_unit_);
    AudioUnitUninitialize(audio_unit_);  // deallocates the audio unit’s resources
    AudioComponentInstanceDispose(audio_unit_);
    audio_unit_ = 0;
  }
}

bool AudioIOS::IsRunning() { return audio_engine_ && audio_engine_->IsRunning(); }

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#if TARGET_OS_IPHONE

#include "aurum/audio_context.h"
#include "aurum/audio_engine.h"

@implementation LynxAurumInterruptionListener

@synthesize backend;

- (id)init:(lynx::canvas::au::AudioIOS *)backend {
  self = [super init];
  self->backend = backend;
  return self;
}

- (void)onAppDidBecomeActive:(UIApplication *)application {
  if (!backend) {
    KRYPTON_LOGI("onAppDidBecomeActive !backend");
    return;
  }

  if (backend->GetAudioUnit() == 0) {
    // init error before, retry again
    KRYPTON_LOGI("init error before, retry again on onAppDidBecomeActive");
    backend->RetryInit();
  } else if (backend->IsRunning() && !backend->IsPaused()) {
    KRYPTON_LOGI("auto resume on onAppDidBecomeActive");
    backend->Resume();
  }
}

- (void)onAudioSessionReset {
  if (!backend) {
    KRYPTON_LOGI("onAudioSessionReset !backend");
    return;
  }

  if (backend->GetAudioUnit() == 0) {
    // init error before, retry again
    KRYPTON_LOGI("init error before, retry again on onAudioSessionReset");
    backend->RetryInit();
  } else if (backend->IsRunning() && !backend->IsPaused()) {
    KRYPTON_LOGI("auto resume on onAudioSessionReset");
    backend->Resume();
  }
}

- (void)onAudioInterrupt:(NSNotification *)notification {
  if (!backend) {
    KRYPTON_LOGI("onAudioInterrupt !backend");
    return;
  }

  NSDictionary *info = notification.userInfo;
  AVAudioSessionInterruptionType type =
      AVAudioSessionInterruptionType([info[AVAudioSessionInterruptionTypeKey] integerValue]);

  KRYPTON_LOGI("onAudioInterrupt ")
      << type << ",audioUnit:" << backend->GetAudioUnit() << ", paused=" << backend->IsPaused()
      << ", interrupted=" << backend->Interrupted();

  if (type == AVAudioSessionInterruptionTypeBegan) {
    if (backend->GetAudioUnit() == 0) {
      return;
    }

    if (backend->IsPaused() || backend->Interrupted()) {
      return;
    }
    backend->SetInterrupted(true);
    AudioOutputUnitStop(backend->GetAudioUnit());
  } else {
    // ended
    if (backend->GetAudioUnit() == 0) {
      // init error before, retry again
      KRYPTON_LOGI("init error before, retry again on onAudioInterrupt");
      backend->RetryInit();
      return;
    }

    if (!backend->Interrupted()) {
      return;
    }
    backend->SetInterrupted(false);
    AVAudioSessionInterruptionOptions options =
        AVAudioSessionInterruptionOptions([info[AVAudioSessionInterruptionOptionKey] integerValue]);
    bool shouldResume = options & AVAudioSessionInterruptionOptionShouldResume;

    if (!backend->IsPaused() && shouldResume) {
      // resume playback
      AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
      [sessionInstance setCategory:AVAudioSessionCategoryPlayback
                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
                             error:nil];

      [sessionInstance setActive:YES error:nil];
      OSStatus status = AudioOutputUnitStart(backend->GetAudioUnit());
      if (status) {
        KRYPTON_LOGW("could not resume after interruption:") << status;
      }
    }
  }
}

@end

#endif
