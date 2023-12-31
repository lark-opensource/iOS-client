//
// Created by sooda on 2020/4/22.
//

#pragma once

#include <vector>
#include <atomic>
#include <memory>
#include <string>
#include "ae_defs.h"

namespace mammon {
  class IResourceFinder;
}

namespace mammon {

typedef enum {
  kEchoReverb = 0,
  kOsilate = 1,
} MusicDspEffectorType;

typedef enum {
  NoteOff = 128,
  NoteOn = 144,
  ControlChange = 176,
  ProgramChange = 192,
  ChannelAftertouch = 208,
  PitchBendChange = 224,
  MetaEvent = 255
} MidiEventType;

class MAMMON_EXPORT Noise2MusicSampler {
public:
  Noise2MusicSampler(int block_size, float sample_rate = 44100.0);

  ~Noise2MusicSampler();

  void Fetch(float **output, int &output_len, float **input);

  void PushMidiEvent(int port_index, MidiEventType type, int channel, int second_byte, int third_byte);

  void PushParameter(int port_number, int parameter_index, float value);

  void UseAsSampler(std::shared_ptr<mammon::IResourceFinder> resource_finder_);

  // definitely return false if not used as sampler
  bool loadFromDescFile(std::string const & desc);
  bool addResourceSearchPath(std::string const & path);

  // possible implementation
//  void SetParameterViaBlockProcess(std::string const & parameter_name, float normalised_parameter_value, double sample_rate);


private:

  int sample_block_size_;
  float sample_rate_;
  void *ctx_;
  void *midi_fifo_;
  void *param_fifo_;
  void *input_;
  void *output_;
  bool is_sampler_;
  std::atomic<int> idx_;
};
}
