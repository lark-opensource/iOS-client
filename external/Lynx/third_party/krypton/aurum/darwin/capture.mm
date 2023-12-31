// Copyright 2022 The Lynx Authors. All rights reserved.

#include <aurum.h>
#include <new>
#include "aurum/audio_engine.h"
#include "aurum/audio_stream.h"
#include "aurum/darwin/audio_ios.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <CoreAudio/AudioHardwareDeprecated.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

class Capture : public CaptureBase {
 public:
  inline Capture(AudioIOS &ios_audio_impl_ptr)
      : ios_audio_impl_(ios_audio_impl_ptr), audio_unit_(0) {
    channels_ = 1;
  }

  virtual ~Capture() { AudioComponentInstanceDispose(audio_unit_); }

  inline bool Setup() { return SetupAudioUnit(); }

  virtual void ForceStart() override {
    if (audio_unit_) {
      ios_audio_impl_.OnCaptureStart();
      AudioOutputUnitStart(audio_unit_);
    }
  }

  virtual void ForceStop() override {
    if (audio_unit_) {
      AudioOutputUnitStop(audio_unit_);
      ios_audio_impl_.OnCaptureStop();
    }
  }

  static OSStatus CaptureCallback(void *in_ref_con, AudioUnitRenderActionFlags *io_action_flags,
                                  const AudioTimeStamp *in_time_stamp, UInt32 in_bus_number,
                                  UInt32 in_number_frames, AudioBufferList *) {
    if (in_number_frames <= 0) {
      return 0;
    }

    Capture *capture = reinterpret_cast<Capture *>(in_ref_con);

    short capture_buffer[AU_CAPTURE_BUF_LEN];
    AudioBufferList buffers;
    buffers.mNumberBuffers = 1;
    buffers.mBuffers[0].mNumberChannels = 1;
    buffers.mBuffers[0].mData = capture_buffer;
    buffers.mBuffers[0].mDataByteSize = sizeof(capture_buffer);

    OSStatus status = AudioUnitRender(capture->audio_unit_, io_action_flags, in_time_stamp,
                                      in_bus_number, in_number_frames, &buffers);
    if (status == 0) {
      capture->WriteMono(capture_buffer, in_number_frames);
    }
    return status;
  }

 private:
  bool SetupAudioUnit() {
    uint32_t parameter;
    AudioComponentDescription desc;
    Float64 out_sample_rate = AU_SAMPLE_RATE;
    const uint32_t max_frames_per_slice = AU_CAPTURE_BUF_LEN;
    AudioStreamBasicDescription output_description;
    AURenderCallbackStruct capture_callback;

#if TARGET_OS_IPHONE
    AVAudioSession *session_instance = [AVAudioSession sharedInstance];
    NSError *error = nil;
    NSTimeInterval buffer_duration = .001;

    if (@available(iOS 10.0, *)) {
      [session_instance setCategory:AVAudioSessionCategoryPlayAndRecord
                        withOptions:AVAudioSessionCategoryOptionMixWithOthers |
                                    AVAudioSessionCategoryOptionAllowBluetooth |
                                    AVAudioSessionCategoryOptionDefaultToSpeaker |
                                    AVAudioSessionCategoryOptionAllowBluetoothA2DP
                              error:&error];
    }

    [session_instance setPreferredIOBufferDuration:buffer_duration error:&error];
    [session_instance setPreferredSampleRate:AU_SAMPLE_RATE error:&error];

    // activate the audio session
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
#endif

    desc.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    parameter = 1;
#else
    desc.componentSubType = kAudioUnitSubType_HALOutput;
    parameter = 0;
#endif

    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;

    AudioComponent comp = AudioComponentFindNext(nullptr, &desc);
    if (!comp) {
      return false;
    }

    if (AudioComponentInstanceNew(comp, &audio_unit_)) {
      goto error;
    }

    if (AudioUnitSetProperty(audio_unit_, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output,
                             0, &parameter, sizeof(UInt32))) {
      goto error;
    }

    parameter = 1;
    if (AudioUnitSetProperty(audio_unit_, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input,
                             1, &parameter, sizeof(UInt32))) {
      goto error;
    }

#if !TARGET_OS_IPHONE
    {
      AudioObjectPropertyAddress addr;
      UInt32 size;
      AudioDeviceID device_id = kAudioDeviceUnknown;
      addr.mSelector = kAudioHardwarePropertyDefaultInputDevice;
      addr.mScope = kAudioObjectPropertyScopeGlobal;
      addr.mElement = kAudioObjectPropertyElementMaster;
      size = sizeof(AudioDeviceID);

      AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, nullptr, &size, &device_id);
      if (device_id == kAudioDeviceUnknown) {
        goto error;
      }

      // get its sample rate
      addr.mSelector = kAudioDevicePropertyNominalSampleRate;
      size = sizeof(Float64);
      AudioObjectGetPropertyData(deviceID, &addr, 0, nullptr, &size, &outSampleRate);
      OSStatus status =
          AudioUnitSetProperty(audio_unit_, kAudioOutputUnitProperty_CurrentDevice,
                               kAudioUnitScope_Global, 0, &device_id, sizeof(AudioDeviceID));
      if (status) {
        goto error;
      }
    }
#else
    out_sample_rate = AU_SAMPLE_RATE;
#endif

    output_description.mSampleRate = out_sample_rate;
    output_description.mFormatID = kAudioFormatLinearPCM;
    output_description.mChannelsPerFrame = 1;
    output_description.mBytesPerFrame = (UInt32)sizeof(int16_t);
    output_description.mBytesPerPacket = sizeof(int16_t);
    output_description.mFramesPerPacket = 1;
    output_description.mFormatFlags =
        kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    output_description.mBitsPerChannel = sizeof(int16_t) * 8;

    if (AudioUnitSetProperty(audio_unit_, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output,
                             1, &output_description, sizeof(output_description))) {
      goto error;
    }

    if (AudioUnitSetProperty(audio_unit_, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0,
                             &output_description, sizeof(output_description))) {
      goto error;
    }

    if (AudioUnitSetProperty(audio_unit_, kAudioUnitProperty_MaximumFramesPerSlice,
                             kAudioUnitScope_Output, 1, &max_frames_per_slice,
                             sizeof(max_frames_per_slice))) {
      goto error;
    }

    sample_rate_ = out_sample_rate;

    capture_callback.inputProc = Capture::CaptureCallback;
    capture_callback.inputProcRefCon = this;

    if (AudioUnitSetProperty(audio_unit_, kAudioOutputUnitProperty_SetInputCallback,
                             kAudioUnitScope_Global, 0, &capture_callback,
                             sizeof(capture_callback)))
      goto error;

    if (AudioUnitInitialize(audio_unit_)) {
      goto error;
    }

    return true;

  error:
    AudioComponentInstanceDispose(audio_unit_);
    audio_unit_ = 0;
    return false;
  }

 private:
  AudioIOS &ios_audio_impl_;
  AudioUnit audio_unit_;
};

Capture *AudioEngine::SetupCapture() {
  if (audio_impl_->IsPaused()) {
    KRYPTON_LOGE("SetupCapture error as engine is paused");
    return nullptr;
  }

  if (audio_capture_) {
    // Avoid developers from creating microphones many times, and audiounit cannot be released
    return static_cast<Capture *>(audio_capture_);
  }

  auto ios_audio_impl = reinterpret_cast<AudioIOS *>(audio_impl_);

  Capture *capture = new Capture(*ios_audio_impl);
  if (capture->Setup()) {
    audio_capture_ = capture;
    return capture;
  }

  delete capture;
  return nullptr;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
