// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_AUDIO_NODE_H_
#define LYNX_KRYPTON_AURUM_AUDIO_NODE_H_

#include <math.h>

#include <algorithm>
#include <memory>
#include <mutex>
#include <string>

#include "Echo2.h"
#include "F0Detection.h"
#include "VolumeDetection.h"
#include "ae_aec.h"
#include "ae_ns.h"
#include "audio_fading.h"
#include "aurum/config.h"
#include "aurum/encoder.h"
#include "aurum/loader.h"
#include "aurum/mixer.h"
#include "aurum/resampler.h"
#include "canvas/base/log.h"
#include "eq.h"
#include "reverb.h"

namespace lynx {
namespace canvas {
namespace au {

inline void ConvertToNonInterlaced(const short *input, float *output,
                                   int samples) {
  for (int i = 0; i < samples; i++) {
    output[i] = *input / 32767.f;
    input += 2;
  }
}

inline void ConvertToFloat(const short *input, float *output, int samples,
                           int channels) {
  samples *= channels;
  for (int i = 0; i < samples; i++) {
    output[i] = *input / 32767.f;
    input++;
  }
}

inline void ConvertToShort(float *input, short *output, int samples,
                           int channels) {
  samples *= channels;
  for (int i = 0; i < samples; i++) {
    output[i] = input[i] * 0x7fff;
  }
}

class AudioContext;

class AudioNodeBase {
 public:
  enum class NodeEvent : uint32_t {
    Waiting = 0,
    CanPlay,
    Playing,
    Seeking,
    Seeked,
    Pause,
    TimeUpdate,
    End,
    Error,
    Stop,
  };

  struct __attribute__((packed)) {
    uint8_t is_sample_source = false;  // The output of SampleSource will be
                                       // added to the data of SampleCallback
    uint8_t is_active = false;   // Active node will execute process by default,
                                 // even if it is not connected to any target
    uint8_t should_aec = false;  // Is echo cancellation required
    uint8_t is_aec_node = false;  // Is aec node
  };

  inline AudioNodeBase() : output_(0, nullptr) {}

  // call OnProcess to get the output of the current node.
  // if OnProcess has been executed in the current loop, the cached result is
  // directly returned
  inline Sample Process(AudioContext &ctx, int len, int generation) {
    if (generation_ == generation) {
      return output_;
    }
    generation_ = generation;

    return output_ = OnProcess(ctx, len);
  }

  int GetID() const { return id_; }

  void Dispatch(NodeEvent event, const AudioContext &ctx,
                std::string err_msg = "");

  virtual void Setup() {}    // initial binding node
  virtual void Cleanup() {}  // disconnect
  /*
   * Maintenance of node connection relationship
   *
   * 1. When calling source.connect(target), calls target.OnConnect(source),
   * Perform different operations according to different target types
   *  a) If target is AudioSourceNode, do nothing
   *  b) If target is AudioProcessorNode, replace the current ource_node
   *       - if source_node not null, call source_node.remove_target(target_id)
   *       - call source.add_target(target_id)
   *       - point source_node to source
   *  c) If target is AudioMixerNode, add source to source_nodes
   *       - call source.add_target(target_id)
   * 2. When calling node.disconnect(), first call
   * node.remove_targets(ctx.nodes), Disconnect from all targets: a) Traverse
   * target_nodes, for all target_ids, call nodes[target_id]->OnDisconnect(node)
   * then node.DisconnectSources() Disconnect from the parent node and perform
   * different operations according to different node types: a) If node is
   * AudioSourceNode, do nothing b) If node is AudioProcessorNode, clear current
   * source_node
   *       - if source_node not null, call source_node.remove_target(node_id)
   * c) If node is AudioMixerNode, clear source_nodes
   *       - Traverse source_nodes, for all sources call
   * source.remove_target(node_id)
   */

  // connet source connect to current node. different node types are handled
  // differently
  virtual void OnConnect(AudioNodeBase *source) = 0;

  // source actively disconnects from the current node
  virtual void OnDisconnect(AudioNodeBase *source) = 0;

  // disconnect the current node from the source node
  virtual void DisconnectSources() = 0;

  virtual ~AudioNodeBase() = default;

  // The target node requests to connect to the current node
  inline void AddTarget(int target_id) {
    if (target_nodes_.empty()) {
      Setup();
    }
    target_nodes_.push_back(target_id);
  }

  // The target node requests to disconnect
  inline void RemoveTarget(int target_id) {
    if (!target_nodes_.empty()) {
      target_nodes_.erase(
          std::find(target_nodes_.cbegin(), target_nodes_.cend(), target_id));
      if (target_nodes_.empty()) {  // run cleanup
        Cleanup();
      }
    }
  }

  // Actively disconnect from the target node
  template <typename NodeType, typename NodeList>
  inline void RemoveTargets(NodeList &nodes) {
    for (auto it = target_nodes_.cbegin(); it != target_nodes_.cend(); it++) {
      NodeType &target = nodes[*it];
      target->OnDisconnect(this);
    }
    target_nodes_.clear();
    Cleanup();
  }

  // Determine whether the node is connected to a microphone node or is itself a
  // microphone node
  inline bool HasMicrophone() { return mic_num_ > 0 ? true : false; }

 protected:
  virtual Sample OnProcess(AudioContext &ctx, int len) = 0;

  int id_;  // AudioNodeID, Assign a value in the constructor of AudioNode
  int generation_ = 0;
  int mic_num_ = 0;

 private:
  std::vector<int> target_nodes_;
  // store the output samples of one cycle.
  // for sourcenode, the data may come from a buffer or a decoder;
  // for gainnode etc, the data is from the source node
  Sample output_;

  friend class AudioNode;
};

// AudioSourceNode : generates audio signals by itself, could not to be
// connected to
class AudioSourceNode : public AudioNodeBase {
 public:
  // Source cannot be the target node of connect
  virtual void OnConnect(AudioNodeBase *source) override final {}

  virtual void OnDisconnect(AudioNodeBase *source) override final {}

  virtual void DisconnectSources() override final {}
};

// AudioProcessorNode, has one source_node. audio signal can be acquired and
// processed with source_node.process()
class AudioProcessorNode : public AudioNodeBase {
 public:
  virtual void OnConnect(AudioNodeBase *source) override final {
    if (source == source_node_) {
      return;
    }
    if (source_node_) {
      // Disconnect from source first
      source_node_->RemoveTarget(id_);
    }
    source->AddTarget(id_);
    source_node_ = source;

    if (source->HasMicrophone()) {
      mic_num_++;
    }
  }

  virtual void OnDisconnect(AudioNodeBase *source) override final {
    __builtin_assume(source == source_node_);
    if (source != source_node_) {
      KRYPTON_LOGE("AudioProcessorNode::OnDisconnect: this node(")
          << source->GetID() << ") is not my source("
          << (source_node_ ? source_node_->GetID() : -1) << ")";
      abort();
    }
    source_node_ = nullptr;

    if (source->HasMicrophone()) {
      mic_num_--;
    }
  }

  virtual void DisconnectSources() override final {
    if (source_node_) {
      source_node_->RemoveTarget(id_);
      source_node_ = nullptr;
    }
  }

  // processor has default OnProcess, to call the process from the source_node
  virtual Sample OnProcess(AudioContext &ctx, int len) override {
    if (!source_node_) {
      return {0, nullptr};
    }

    return source_node_->Process(ctx, len, generation_);
  }

 private:
  AudioNodeBase *source_node_ = nullptr;
};

// AudioMixerNode: mix audio from more than one source_node, support
// post-processing
class AudioMixerNode : public AudioNodeBase {
 public:
  virtual void OnConnect(AudioNodeBase *source) override final {
    AU_LOCK(nodes_lock_);
    bool exists = std::find(source_nodes_.cbegin(), source_nodes_.cend(),
                            source) != source_nodes_.cend();
    AU_UNLOCK(nodes_lock_);
    if (exists) {
      return;
    }

    source->AddTarget(id_);
    AU_LOCK(nodes_lock_);
    source_nodes_.push_back(source);
    AU_UNLOCK(nodes_lock_);

    if (source->HasMicrophone()) {
      mic_num_++;
    }
  }

  virtual void OnDisconnect(AudioNodeBase *source) override final {
    AU_LOCK(nodes_lock_);
    source_nodes_.erase(
        std::find(source_nodes_.cbegin(), source_nodes_.cend(), source));
    AU_UNLOCK(nodes_lock_);

    if (source->HasMicrophone()) {
      mic_num_--;
    }
  }

  virtual void DisconnectSources() override final {
    std::vector<AudioNodeBase *> source_nodes_to_clear;
    AU_LOCK(nodes_lock_);
    source_nodes_.swap(source_nodes_to_clear);
    AU_UNLOCK(nodes_lock_);

    for (auto it = source_nodes_to_clear.cbegin();
         it != source_nodes_to_clear.cend(); it++) {
      AudioNodeBase *source = *it;
      source->RemoveTarget(id_);
    }
  }

  // OnProcess will traverse all nodes and mix the results.
  // if the output is not empty, post will calle PostProcess
  virtual Sample OnProcess(AudioContext &ctx, int len) override;

  virtual void PostProcess(AudioContext &ctx, Sample output) = 0;

 protected:
  static constexpr int channels_ = 2;

 private:
  int nodes_lock_ = 0;
  std::vector<AudioNodeBase *> source_nodes_;
  Mixer mixer_;
};

class AudioDestinationNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override {}
};

class AudioBufferSourceNode : public AudioSourceNode, public SampleSource {
 public:
  virtual Sample OnProcess(AudioContext &ctx, int len) override;

  void SetBuffer(int channels, int sample_rate, int length, const float *ptr);
  void ClearBuffer();
  void SetLoop(bool val) { loop_ = val; }
  void Start(float offset) {
    total_offset_ = sample_offset_ = offset * sample_rate_;
    started_ = true;
  }
  void Stop() { started_ = false; }
  uint32_t TotalOffset() const { return total_offset_; }

 private:
  virtual void ReadSamples(AudioContext &ctx, Sample &output,
                           int samples) override;

 private:
  bool loop_ = false;
  bool started_ = false;
  int length_ = 0;
  const float *ptr_ = nullptr;
  uint32_t sample_offset_ = 0;
  uint32_t total_offset_ = 0;
};

class Audio;

class AudioElementSourceNode : public AudioSourceNode, public SampleSource {
 public:
  virtual Sample OnProcess(AudioContext &ctx, int len) override;

  inline AudioElementSourceNode(Audio &audio) : audio_(audio) {}

  inline void OnError(AudioContext &ctx, std::string err_msg);

 private:
  Audio &audio_;

  inline void OnMeta(const DecoderBase *decoder);
  virtual void ReadSamples(AudioContext &ctx, Sample &output,
                           int samples) override;
};

class StreamBase;

class AudioStreamSourceNode : public AudioSourceNode, private SampleSource {
 public:
  inline AudioStreamSourceNode(StreamBase *stream, int channels,
                               int sample_rate)
      : stream_(stream) {
    channels_ = channels;
    sample_rate_ = sample_rate;
    mic_num_ = 1;
  }

  void Setup() override;

  void Cleanup() override;

  virtual Sample OnProcess(AudioContext &ctx, int len) override {
    if (!stream_) {
      return {0, nullptr};
    }
    return Resample(ctx, len);
  }

  virtual ~AudioStreamSourceNode() override;

 private:
  StreamBase *const stream_;
  virtual void ReadSamples(AudioContext &ctx, Sample &output,
                           int samples) override;
};

class AudioGainNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override;
  float gain_value = 1.0;
};

class AudioAnalyserNode : public AudioProcessorNode {
 public:
  virtual Sample OnProcess(AudioContext &ctx, int len) override;

  virtual ~AudioAnalyserNode() override { free(buffer_); }

  void GetByteData(bool is_frequency, int len, unsigned char *ptr);

  void GetFloatData(bool is_frequency, int len, float *ptr);

  template <int fftSize>
  inline void SetFFTSize();

  inline void DoFFT();

  inline AudioAnalyserNode() { SetFFTSize<2048>(); }

  inline void SetDecMin(short val) { dec_min_ = val; }
  inline void SetDecMax(short val) { dec_max_ = val; }

 private:
  void *buffer_ = nullptr;

  int16_t *recv_cache_, *time_samples_, *freq_samples_;
  float *fft_buf_, *fft_win_, *fft_factor_;
  size_t *ip_;
  bool transformed_ = true;

  unsigned short count_ = 0, pos_ = 0;
  short dec_min_ = -100, dec_max_ = -30;

  int buf_lock_ = 0;
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

class AudioReverbNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }

  inline AudioReverbNode()
      : reverb_(AU_SAMPLE_RATE, channels_, room_size_, hf_damping_,
                stereo_depth_, dry_, wet_, dry_gain_db_, wet_gain_db_,
                dry_only_, wet_only_) {}

  void SetParam(int type, float value);

 private:
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  float room_size_ = 0.6f;
  float hf_damping_ = 0.5f;
  float stereo_depth_ = 1.0f;
  float dry_ = 0.5f;
  float wet_ = 0.5f;
  float dry_gain_db_ = 0.0;
  float wet_gain_db_ = 0.0;
  bool wet_only_ = false;
  bool dry_only_ = false;

  mammon::Reverb reverb_;
  float input_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
  float output_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
};

class AudioEqualizerNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }
  inline AudioEqualizerNode();

 public:
  std::map<std::string, float> params;
  std::mutex param_lock;
  bool need_update_param = false;

 private:
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  std::unique_ptr<mammon::Effect> processor_ = nullptr;
  float input_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
};

class AudioDelayNode : public AudioMixerNode {
 public:
  void SetDelay(float delay) {
    if (delay < 0 || this->delay_ == delay) {
      return;
    }
    this->delay_ = delay;
    ResetParams();
  }

  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }

  inline AudioDelayNode(float delay)
      : delay_(delay),
        echo1_(AU_SAMPLE_RATE, delay, feedback_, wet_, dry_),
        echo2_(AU_SAMPLE_RATE, delay, feedback_, wet_, dry_) {}

 private:
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  float delay_ = 0.0f;
  static constexpr float feedback_ = 0.0;
  static constexpr float wet_ = 1.0f;
  static constexpr float dry_ = 0.0f;
  mammon::Echo2 echo1_, echo2_;
  float input_buffer[AU_PLAYBACK_BUF_LEN * channels_];

  void ResetParams() {
    echo1_.reset(AU_SAMPLE_RATE, delay_, feedback_, wet_, dry_);
    echo2_.reset(AU_SAMPLE_RATE, delay_, feedback_, wet_, dry_);
  }
};

class AudioAECNode : public AudioMixerNode {
 public:
  AudioAECNode() : bg_(0, nullptr) {
    InitAec();
    is_aec_node = true;
  }

  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }

  inline void SetAecBackgroundSample(Sample bg) { bg_ = bg; }

 private:
  void InitAec();
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  Sample bg_;  // Data of background sound nodes to be eliminated
  std::unique_ptr<mammon::AecMicSelection> aec_ = nullptr;
  std::unique_ptr<mammon::NoiseSuppression> ns_ = nullptr;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-private-field"
  float bg_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
  float fr_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
#pragma clang diagnostic pop
};

class AudioF0DetectionNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }

  inline AudioF0DetectionNode(float min, float max) { SetF0Range(min, max); }

  virtual ~AudioF0DetectionNode() override { DoPreDestroy(); }

  void SetF0Range(float min, float max) {
    if (min < 0.0f || max > 10000.0f || min > max) {
      return;
    }
    this->min_ = min;
    this->max_ = max;
  }

  void GetF0DetectionData(int length, float *time, float *data);

 private:
  void DoPreDestroy();
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  int buf_lock_ = 0;
  float min_ = 400.0f;
  float max_ = 800.0f;
  float max_strorage_time_ = 500.0f;
  F0DPointer f0_detector_ = nullptr;
  std::vector<std::pair<float, float>> f0_pairs_;
  std::vector<std::pair<float, float>> cache_;
};

class AudioVolumeDetectionNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }

  virtual ~AudioVolumeDetectionNode() override { DoPreDestroy(); }

  void GetVolumeDetectionData(int length, float *time, float *data);

 private:
  void DoPreDestroy();
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  int buf_lock_ = 0;
  float max_strorage_time_ = 500.0f;
  VDPointer vd_pointer_ = nullptr;
  std::vector<std::pair<float, float>> cache_;
  std::vector<std::pair<float, float>> volume_paris_;
};

class AudioFadingNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override {
    DoPostProcess(ctx, output);
  }

  virtual ~AudioFadingNode() override { DoPreDestroy(); }

  void *GetAudioFadingPointer() { return fading_ptr_; }

 private:
  void DoPreDestroy();
  void DoPostProcess(AudioContext &ctx, Sample output);

 private:
  void *fading_ptr_ = nullptr;
  float input_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
  float output_buffer_[AU_PLAYBACK_BUF_LEN * channels_];
};

#pragma clang diagnostic pop

class AudioOscillatorNode : public AudioSourceNode {
 public:
  virtual Sample OnProcess(AudioContext &ctx, int len) override;

  void SetFrequency(float val) { frequency_ = val; }
  void SetStarted(bool val) { started_ = val; }
  void SetWaveForm(int val) { wave_form_ = val; }
  void SetSampleOffset(uint64_t val) { sample_offset_ = val; }

 private:
  bool started_ = false;
  float frequency_ = 440;
  int wave_form_ = 0;  // default sin wave
  uint64_t sample_offset_ = 0;
  SampleFormat buffer_[AU_STREAM_BUF_LEN * 2];
};

class EncoderBase;

class AudioStreamFileWriterNode : public AudioMixerNode {
 public:
  virtual void PostProcess(AudioContext &ctx, Sample output) override final;
  void Destroy();

  virtual ~AudioStreamFileWriterNode() override { Destroy(); }

  void SetEncoder(EncoderBase *val) { encoder_ = val; }
  bool HasEncoder() const { return encoder_ != nullptr; }

 protected:
  EncoderBase *encoder_ = nullptr;
  int encoder_lock_ = 0;
};

class AudioFastForwardNode : public AudioStreamFileWriterNode {
 public:
  virtual Sample OnProcess(AudioContext &ctx, int len) override;
  void SetFFWDCountDown(int val) { ffwd_count_down_ = val; }
  void SetStartFlag(bool val) { start_flag_ = val; }

 private:
  struct StopFastForwardTask;
  bool start_flag_ = false;
  int ffwd_count_down_ = -1;
  int ffwd_generation_ = 0;
};

class AudioNode {
 public:
  inline AudioNode(int id, AudioNodeBase *handle) : handle_(handle) {
    handle_->id_ = id;
  }

  inline ~AudioNode() {
    // !!! Destroy will not call the destructor of the base class.
    // Even if the base class writes destroy, it will not be called.
    // It needs to be called actively
    delete handle_;
  }

  template <typename T>
  inline T &As() {
    return *static_cast<T *>(handle_);
  }

  inline AudioNodeBase *operator->() { return handle_; }

  // prev node in active node list; prev of nodes[0] is also used ad the tail of
  // list
  AudioNode *active_prev = nullptr;
  // next node in active node list
  AudioNode *active_next = nullptr;

  inline void AppendToActiveList(AudioNode &dest) {
    AudioNode *tail = dest.active_prev;
    this->active_prev = tail;
    tail->active_next = this;
    dest.active_prev = this;
  }

  inline void RemoveFromActiveList(AudioNode &dest) {
    AudioNode *prev = this->active_prev;
    prev->active_next = this->active_next;
    (this->active_next ?: &dest)->active_prev = prev;
    this->active_next = nullptr;
  }

 private:
  AudioNodeBase *const handle_;
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

namespace lynx {
namespace canvas {
template <int fft_size>
void au::AudioAnalyserNode::SetFFTSize() {
  AU_LOCK(buf_lock_);

  if (buffer_) {
    free(buffer_);
    buffer_ = 0;
  }

  count_ = fft_size;
  pos_ = 0;

  struct Buffer {
    int16_t recv_cache[fft_size];    // The received data is temporarily stored
                                     // here when it is less than one grid
    float fft_buf[fft_size];         // temporary buffer for FFT transform
    int16_t time_samples[fft_size];  // time domain data
    int16_t freq_samples[fft_size >> 1];  // frequency domain data
    float fft_factor[fft_size];           // FFT premultiplier factor
    float fft_win[fft_size >> 1];         // FFT window
    size_t ip[0];
  };

  size_t ip_len = size_t(2.999 + sqrt(fft_size >> 1)) * sizeof(size_t);
  buffer_ = malloc(sizeof(Buffer) + ip_len);
  Buffer &b = *reinterpret_cast<Buffer *>(buffer_);
  memset(buffer_, 0, sizeof(Buffer) + sizeof(size_t));

  for (int i = 0; i < fft_size; ++i) {
    b.fft_factor[i] = (1.f - cosf(2 * float(M_PI) * i / fft_size)) / 65536;
  }

  recv_cache_ = b.recv_cache;
  fft_buf_ = b.fft_buf;
  time_samples_ = b.time_samples;
  freq_samples_ = b.freq_samples;
  fft_win_ = b.fft_win;
  fft_factor_ = b.fft_factor;
  ip_ = b.ip;
  pos_ = 0;

  AU_UNLOCK(buf_lock_);
}
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_AUDIO_NODE_H_
