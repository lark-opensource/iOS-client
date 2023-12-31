// Copyright 2022 The Lynx Authors. All rights reserved.

#include <AudioToolbox/AudioToolbox.h>

#include "aurum/audio_context.h"
#include "aurum/aurum.h"
#include "aurum/config.h"
#include "aurum/decoder.h"
#include "aurum/decoder/buffered_fiber_decoder.h"
#include "aurum/decoder/chunk_loader.h"
#include "aurum/decoders.h"
#include "aurum/loader.h"
#include "canvas/base/log.h"

#define PRT_ERR(__status)                                                    \
  KRYPTON_LOGW("<#VTDecoder#> ") << __LINE__ << ": status " << int(__status) \
                                 << " '(" << (const char *)&__status << ")'";

namespace lynx {
namespace canvas {
namespace au {

struct PacketInfo {
  AudioBuffer buffer;
  uint32_t packets_length;
  AudioStreamPacketDescription *packets;

  static OSStatus AudioConverterComplexInputDataProc(
      AudioConverterRef in_audio_converter, UInt32 *io_number_data_packets,
      AudioBufferList *io_data,
      AudioStreamPacketDescription **out_data_packet_description,
      void *in_user_data) {
    auto info = reinterpret_cast<PacketInfo *>(in_user_data);
    *io_number_data_packets = info->packets_length;
    if (!info->packets_length) {
      return uint32_t('MOAR');
    }

    *out_data_packet_description = info->packets;
    io_data->mBuffers[0] = info->buffer;
    info->packets_length = 0;
    return 0;
  }
};

static constexpr int STACK_SIZE = 128 * 1024;

class VTDecoder : public FiberLoader<STACK_SIZE> {
 public:
  inline VTDecoder(const uint32_t *ints, LoaderBase &loader)
      : FiberLoader<STACK_SIZE>(loader) {
    input_desc_.mSampleRate = 0;

    if (ints[1] == htonl('ftyp') || ints[1] == htonl('moov')) {  // mp4a
      type_ = DecoderType::MP4;
      chunk_loader_ = M4A();
    } else if ((ints[0] & 0xf0ff) == 0xf0ff) {
      type_ = DecoderType::AAC;
      chunk_loader_ = new RawChunkLoader<STACK_SIZE>(*this);
    } else {
      type_ = DecoderType::MP3;
      chunk_loader_ = new RawChunkLoader<STACK_SIZE>(*this);
    }
  }

  void OnReady() {
    const AudioStreamBasicDescription output_desc = {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags =
            kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
        .mSampleRate = input_desc_.mSampleRate,
        .mChannelsPerFrame = 2,
        .mBitsPerChannel = 16,
        .mBytesPerPacket = 4,
        .mFramesPerPacket = 1,
        .mBytesPerFrame = 4,
        .mReserved = 0,
    };

    OSStatus status = AudioConverterNew(&input_desc_, &output_desc, &decoder_);
    if (status != 0) {
      PRT_ERR(status);
      state_ = DecoderState::Error;
      return;
    }

    meta_.channels = input_desc_.mChannelsPerFrame;
    meta_.sample_rate = output_desc.mSampleRate;
    if (meta_.samples == -1 && bit_rate && byte_count) {
      meta_.samples = int32_t(
          (int64_t(byte_count) * int64_t(meta_.sample_rate) << 3) / bit_rate);
    }
    KRYPTON_LOGV("samples ") << bit_rate << byte_count << "->" << meta_.samples;

    state_ = DecoderState::Meta;
  }

  void onPackets(UInt32 in_number_bytes, UInt32 in_number_packets,
                 const void *in_input_data,
                 AudioStreamPacketDescription *in_packet_descriptions) {
    PacketInfo info;
    info.buffer.mNumberChannels = input_desc_.mChannelsPerFrame;
    info.buffer.mData = (void *)in_input_data;
    info.buffer.mDataByteSize = in_number_bytes;
    info.packets_length = in_number_packets;
    info.packets = in_packet_descriptions;

    for (;;) {
      UInt32 frames = FRAMES_PER_PACKET;
      short sample_buffer[FRAMES_PER_PACKET * 2];

      AudioBufferList output_buffer;
      output_buffer.mNumberBuffers = 1;
      output_buffer.mBuffers[0].mData = sample_buffer;
      output_buffer.mBuffers[0].mDataByteSize = sizeof(sample_buffer);

      OSStatus status = AudioConverterFillComplexBuffer(
          decoder_, PacketInfo::AudioConverterComplexInputDataProc, &info,
          &frames, &output_buffer, nullptr);
      if (frames) {
        buffer_ = sample_buffer;
        buffer_start_ = buffer_end_;
        buffer_end_ = buffer_start_ + frames;
        if (buffer_end_ > next_sample_) {
          Yield();
        }
      }
      if (status != 0) {
        if (status != 'MOAR') {
          PRT_ERR(status);
        }
        return;
      }
    }
  }

  void Process() override {
    constexpr bool is_running = true;

    meta_.samples = -1;
    int channels, srate;
    if (!chunk_loader_->GuessType(channels, srate, meta_.samples)) {
      state_ = DecoderState::Error;
      return;
    }
    AudioFileTypeID fileTypeID =
        type_ == DecoderType::MP3 ? kAudioFileMP3Type : kAudioFileAAC_ADTSType;

    OSStatus status =
        AudioFileStreamOpen(this, AudioFileStream_PropertyListenerProc,
                            AudioFileStream_PacketsProc, fileTypeID, &stream_);
    if (status != 0) {
      PRT_ERR(status);
      return;
    }

    while (is_running) {
      int flags = 0;
      // seek || need to start from scratch
      if (next_sample_ < buffer_end_) {
        chunk_loader_->Rewind();
        buffer_end_ = 0;

        flags = kAudioFileStreamParseFlag_Discontinuity;
      }

      ChunkInfo chunk_info;
      if (!chunk_loader_->NextChunk(chunk_info, 1024)) {
        running_ = false;
        state_ = DecoderState::Error;
        return;
      }

      if (chunk_info.Length() == 0) {
        state_ = DecoderState::EndOfFile;
        Yield();
        continue;
      }

      OSStatus status = AudioFileStreamParseBytes(stream_, chunk_info.Length(),
                                                  chunk_info.Data(), flags);

      if (status != 0) {
        PRT_ERR(status);
        state_ = DecoderState::Error;
        running_ = false;
        return;
      }
    }
  }

  virtual ~VTDecoder() { delete chunk_loader_; }

  void OnDataFormat() {
    UInt32 property_size = sizeof(input_desc_);
    AudioFileStreamGetProperty(stream_, kAudioFileStreamProperty_DataFormat,
                               &property_size, &input_desc_);
  }

  void OnFetchFormatList() {
    OSStatus status = 0;
    UInt32 decoder = 0, format = 0;
    UInt32 format_size = 0, decoder_size = 0;

    // Get Format List Total Size
    status = AudioFileStreamGetPropertyInfo(
        stream_, kAudioFileStreamProperty_FormatList, &format_size, nullptr);
    if (status != 0) {
      if (status != kAudioFileStreamError_DataUnavailable) {
        KRYPTON_LOGW("Fail to get format list size ") << status;
      }
      return;
    }

    // Fetch Supported Codecs
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0,
                                        nullptr, &decoder_size);

    if (status != 0) {
      KRYPTON_LOGW("Fail to fetch format list ") << status;
      return;
    }

    // Get Format List
    format = format_size / sizeof(AudioFormatListItem);
    decoder = decoder_size / sizeof(OSType);
    AudioFormatListItem *formats = new AudioFormatListItem[format];
    OSType *decoders = new OSType[decoder];

    status = AudioFileStreamGetProperty(
        stream_, kAudioFileStreamProperty_FormatList, &format_size, formats);
    if (status != 0) {
      KRYPTON_LOGW("Fail to fetch format list ") << status;
      goto fail;
    }

    status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0,
                                    nullptr, &decoder_size, decoders);
    if (status != 0) {
      KRYPTON_LOGW("Fail to fetch format list ") << status;
      goto fail;
    }

    // Fetch the decoder
    for (uint32_t i = 0; i < format; i++) {
      OSType decoder_id = formats[i].mASBD.mFormatID;
      for (unsigned int j = 0; j < decoder; ++j) {
        if (decoder_id == decoders[j]) {
          input_desc_ = formats[i].mASBD;
        }
      }
    }
  fail:
    delete[] decoders;
    delete[] formats;
  }

  void OnMagic() {
    UInt32 cookie_size = 0;
    char cookie[4096];
    OSStatus status = AudioFileStreamGetProperty(
        stream_, kAudioFileStreamProperty_MagicCookieData, &cookie_size,
        cookie);
    // if there is an error here, then the format
    // doesn't have a cookie, so on we go
    if (status == 0) {
      AudioConverterSetProperty(decoder_,
                                kAudioConverterDecompressionMagicCookie,
                                cookie_size, cookie);
    }
  }

  OSStatus OnPacketInfo() {
    OSStatus status = 0;

    // if the bitstream file contains priming info, overwrite the audio
    // converter's priming info with the one got from the bitstream to do
    // correct trimming
    AudioFilePacketTableInfo src_pti;
    UInt32 size = sizeof(src_pti);

    // try to get priming info from bitstream file
    status = AudioFileStreamGetProperty(
        stream_, kAudioFileStreamProperty_PacketTableInfo, &size, &src_pti);

    // has priming info
    if (status != 0) {
      return 0;
    }

    // overwrite audio converter's priming info
    AudioConverterPrimeInfo prime_info;

    // overwrite the audio converter's prime info
    prime_info.leadingFrames = src_pti.mPrimingFrames;
    // since the audio converter does not cut off trailing zeros
    prime_info.trailingFrames = 0;

    status = AudioConverterSetProperty(decoder_, kAudioConverterPrimeInfo,
                                       sizeof(prime_info), &prime_info);
    return status;
  }

  uint64_t byte_count = 0;
  uint32_t bit_rate = 0;

  void OnBitRate() {
    UInt32 size = sizeof(bit_rate);
    OSStatus ret = AudioFileStreamGetProperty(
        stream_, kAudioFileStreamProperty_BitRate, &size, &bit_rate);
    if (0 != ret) {
      KRYPTON_LOGW("AudioFileStreamGetProperty error: ") << ret;
    }
  }

  void OnByteCount() {
    UInt32 size = sizeof(byte_count);
    OSStatus ret = AudioFileStreamGetProperty(
        stream_, kAudioFileStreamProperty_AudioDataByteCount, &size,
        &byte_count);
    if (0 != ret) {
      KRYPTON_LOGW("AudioFileStreamGetProperty error: ") << ret;
    }
  }

  static void AudioFileStream_PropertyListenerProc(
      void *in_client_data, AudioFileStreamID in_audio_file_stream,
      AudioFileStreamPropertyID in_property_id,
      AudioFileStreamPropertyFlags *io_flags) {
#if 0
        uint32_t tmp = htonl(in_property_id);
        KRYPTON_LOGV("recv property ") << &tmp;
#endif
    VTDecoder *decoder = reinterpret_cast<VTDecoder *>(in_client_data);

    switch (in_property_id) {
      case kAudioFileStreamProperty_DataFormat:
        decoder->OnDataFormat();
        break;
      case kAudioFileStreamProperty_MagicCookieData:
        decoder->OnMagic();
        break;
      case kAudioFileStreamProperty_PacketTableInfo:
        decoder->OnPacketInfo();
        break;
      case kAudioFileStreamProperty_FormatList:
        decoder->OnFetchFormatList();
        break;
      case kAudioFileStreamProperty_BitRate:
        decoder->OnBitRate();
        break;
      case kAudioFileStreamProperty_AudioDataByteCount:
        decoder->OnByteCount();
        break;
      case kAudioFileStreamProperty_ReadyToProducePackets:
        decoder->OnReady();
        break;
      default:
        break;
    }
  }

  static void AudioFileStream_PacketsProc(
      void *in_client_data, UInt32 in_number_bytes, UInt32 in_number_packets,
      const void *in_input_data,
      AudioStreamPacketDescription *in_packet_descriptions) {
    ((VTDecoder *)in_client_data)
        ->onPackets(in_number_bytes, in_number_packets, in_input_data,
                    in_packet_descriptions);
  }

 private:
  static constexpr int FRAMES_PER_PACKET = 1024;
  ChunkLoader *chunk_loader_;
  AudioFileStreamID stream_;
  AudioConverterRef decoder_;
  AudioStreamBasicDescription input_desc_;
};

class VTDecoderImpl : public Decoder {
 public:
  static VTDecoderImpl &Instance() {
    static VTDecoderImpl decoder_impl;
    return decoder_impl;
  }

  virtual DecoderBase *Create(const void *head, LoaderBase &loader) override {
    const uint32_t *ints = reinterpret_cast<const uint32_t *>(head);
    if ((ints[0] & 0xffffff) == 0x334449  // mp3 '3DI' = 0x334449
        || (ints[0] & 0xe2ff) == 0xe2ff   // mp3
        || (ints[0] & 0xf0ff) == 0xf0ff   // ADTS
        || ints[1] == htonl('ftyp')       // mp4
        || ints[1] == htonl('moov')       // mp4
    )
      return new VTDecoder(ints, loader);
    return nullptr;
  }
};

namespace decoder {
class Decoder &AudioToolbox() { return VTDecoderImpl::Instance(); }
}  // namespace decoder

}  // namespace au
}  // namespace canvas
}  // namespace lynx
