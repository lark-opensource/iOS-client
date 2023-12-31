// Copyright 2022 The Lynx Authors. All rights reserved.

// AudioContext declaration, used to automatically generate binding.h and
// js/src/binding.js. If this file has been changed, please run `node
// js/build/gen_audio_context.js` to re-generate files.

// You may run `pnpm install` first in aurum
// path to install the pnpm related modules.

// clang-format off
enum class AudioState {
  Play = 0,
  Pause = 1,
  Stop = 2,
};

AUDIO_API void Connect(AudioNodeID src_id, AudioNodeID dst_id);  // Connect Node
AUDIO_API void Disconnect(AudioNodeID src_id);  // Disconnect Node

AUDIO_API AudioNodeID CreateBufferSourceNode();  // Create Buffer Source Node
AUDIO_API void SetBuffer(AudioNodeID node_id, int channels, int sample_rate, int length, const float* ptr);  // Set Buffer for BufferSourceNode
AUDIO_API void ClearBuffer(AudioNodeID node_id);  // Clear Buffer for BufferSourceNode
AUDIO_API void SetBufferLoop(AudioNodeID node_id, bool loop);  // Set Loop for BufferSourceNode
AUDIO_API void StartBuffer(AudioNodeID node_id, float offset);  // Start Play for BufferSourceNode
AUDIO_API void StopBuffer(AudioNodeID node_id);  // Stop Play for BufferSourceNode

AUDIO_API void SetAudioState(AudioID audio, AudioState state);  // Set Audio State
AUDIO_API void SetAudioCurrentTime(AudioID audio, double time);      // Set Audio Current Time
AUDIO_API double GetAudioCurrentTime(AudioID audio);  // Get Audio Current Time
AUDIO_API void SetAudioLoop(AudioID audio, bool loop);  // Set Loop for Audio
AUDIO_API void SetAudioAutoPlay(AudioID audio, bool autoplay);    // Set AutoPlay for Audio
AUDIO_API double GetAudioDuration(AudioID audio);  // Get Audio Duration
AUDIO_API void SetAudioVolume(AudioID audio, double volume);  // Set Volume for Audio
AUDIO_API void SetAudioStartTime(AudioID audio, double start_time);  // Set StartTime for Audio
AUDIO_API bool GetAudioPaused(AudioID audio);  // Get Paused Status for Audio

AUDIO_API AudioID CreateAudio(bool loop, bool autoplay, double start_time, double volume);  // Create Audio
AUDIO_API void ResetAudioLoader(AudioID audio, Utf8Value path);  // Reset Loader for Audio ID
AUDIO_API AudioNodeID CreateAudioElementSourceNode(AudioID loader_id);  // Create Loader Node

AUDIO_API AudioNodeID CreateGainNode();  // Create Gain Node
AUDIO_API void SetGainValue(AudioNodeID node_id, float value);  // Set Gain Value for GainNode

AUDIO_API AudioNodeID CreateStreamSourceNode(StreamID stream_id);  // Create Stream Based Audio Node

enum class AnalyserParam {
  FFTSize = 0,
  MinDecibels = 1,
  MaxDecibels = 2,
};

AUDIO_API AudioNodeID CreateAnalyserNode();  // Create Analyser Node
AUDIO_API void UpdateAnalyserParam(AudioNodeID node_id, AnalyserParam param_id, int value);  // Updatee Analyser Param
AUDIO_API void GetAnalyserDataByte(AudioNodeID node_id, bool is_frequency, int length, unsigned char* buffer_ptr);  // Get Analyser Data (Time Domain or Frequency. Domain Visualization Data) in Byte Format
AUDIO_API void GetAnalyserDataFloat(AudioNodeID node_id, bool is_frequency, int length, float* buffer_ptr);  // Get Analyser Data (Time Domain or Frequency Domain Visualization Data) in Float Format

AUDIO_API void AudioNodeIsSampleSource(AudioNodeID node_id, bool is_sample_source); // AudioNode Is SampleSource
AUDIO_API void DecodeAudioData(int execute_id, int length, const void* ptr);  // Asynchronously Decode ArrayBuffer
AUDIO_API void SetAudioBufferLoader(AudioID audio, int length, const void* ptr);  // Copy ArrayBuffer and Set BufferLoader

AUDIO_API AudioNodeID CreateReverbNode(); // Create Reverb Node
AUDIO_API void SetReverbParam(AudioNodeID node_Id, int type, float value); // Set Reverb Param

AUDIO_API AudioNodeID CreateEqualizerNode(); // Create Equalizer Node
AUDIO_API void SetEqualizerNodeParams(AudioNodeID node_id, float* params, int length); // Set Equalizer Node Params

AUDIO_API AudioNodeID CreateDelayNode(float delay); // Create Delay Node
AUDIO_API void SetDelay(AudioNodeID node_id, float new_delay); // Set Delay

AUDIO_API AudioNodeID CreateF0DetectionNode(float min, float max); // Create F0 Detection Node

AUDIO_API AudioNodeID CreateVolumeDetectionNode(); // Create Volume Detection Node

AUDIO_API AudioNodeID CreateAECNode(int sample_rate); // Create AEC Node

AUDIO_API AudioNodeID CreateFadingNode(); // Create Fading Node

AUDIO_API void SetFadingDurations(AudioNodeID node_id, uint64_t total_ms, uint64_t fading_in_ms, uint64_t fading_out_ms); // Set Fading Durations

AUDIO_API void SetFadingCurves(AudioNodeID node_id, uint32_t in_curve, uint32_t out_curve); // Set Fading Curves

AUDIO_API void SetFadingPosition(AudioNodeID node_id, uint64_t position_in_ms); // Set Fading Position

AUDIO_API void GetF0DetectionData(AudioNodeID node_id, int length, float* time_array, float* data_rray); // Get F0 DetectionData

AUDIO_API void GetVolumeDetectionData(AudioNodeID node_id, int length, float* time_array, float* data_array); // Get Volume DetectionData

AUDIO_API AudioNodeID CreateOscillatorNode();  // Create Oscillator Node
AUDIO_API void SetOscillatorFreq(AudioNodeID node_id, float freq);  // Set Oscillator Frequence
AUDIO_API void SetOscillatorDetune(AudioNodeID node_id, float detune);  // Set Oscillator Detune
AUDIO_API void SetOscillatorWave(AudioNodeID node_id, int waveform);  // Set Oscillator Wav
AUDIO_API void StartOscillator(AudioNodeID node_id, float offset); // Start Oscillator
AUDIO_API void StopOscillator(AudioNodeID node_id); // Stop Oscillator

AUDIO_API AudioNodeID CreateStreamFileWriterNode();  // Create Stream File Writer Node
AUDIO_API bool StartStreamFileWriter(AudioNodeID node_id, Utf8Value path);  // Init Encoder and  Start File Writting
AUDIO_API void StopStreamFileWriter(AudioNodeID node_id);  // Stop File Writting

AUDIO_API AudioNodeID CreateFastForwardNode();  // Create FastForward Node
AUDIO_API bool StartFastForward(AudioNodeID node_id, Utf8Value path, int samples);  // Fast Output in Audio Thread

AUDIO_API int GetBufferOffset(AudioNodeID node_id);  // Get Current Offset of BufferSource

AUDIO_API void RefContext();    // RefMode Ref
AUDIO_API void UnrefContext();  // RefMode Unref

// clang-format on
