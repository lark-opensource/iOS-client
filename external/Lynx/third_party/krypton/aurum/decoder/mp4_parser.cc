// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/decoder/mp4_parser.h"

#include <cstring>

namespace lynx {
namespace canvas {
namespace au {

void MP4Parser::ADTSContext::OnExtraData(const uint8_t *pbuf) {
  profile = (pbuf[0] >> 3);
  sample_rate_index = ((pbuf[0] & 0x07) << 1) + (pbuf[1] >> 7);
  channel_conf = (pbuf[1] & 0x78) >> 3;
}

bool MP4Parser::ParseHead() {
  struct Tag {
    uint32_t size_be;
    uint32_t name;
  };

  size_t offset = 0;
  ChunkInfo info;

  while (this->Read(offset, sizeof(Tag), info)) {
    offset += 8;

    const Tag *tag = reinterpret_cast<const Tag *>(info.Data());
    KRYPTON_LOGV("top level block") << ((const char *)&tag->name);

    // If 0, the last box.
    if (tag->size_be == 0) {
      break;
    }

    uint32_t size = htonl(tag->size_be);
    // If 1, read the large size panel.
    if (size == 1) {
      if (!this->Read(offset, 8, info)) {
        return false;
      }
      size = htonl(reinterpret_cast<const uint32_t *>(info.Data())[1]);
    }

    // We only care about the moov box
    if (tag->name == htonl('moov')) {
      if (!this->Read(offset, size - 8, info)) {
        return false;
      }
      return ParseMoov(info.Data());
    }

    offset += size - 8;
  }

  return false;
}

bool MP4Parser::ParseMoov(const void *data) {
  bool pass = false;

  Box::Iter moov_iter =
      reinterpret_cast<const Box *>(reinterpret_cast<const uint8_t *>(data) - 8)
          ->GetIter();
  const Box *box;

  while ((box = moov_iter.Next()) != nullptr) {
    if (!box->Is<'trak'>()) {
      continue;
    }

    Box::Iter trak_iter = box->GetIter();
    bool is_audio_track = false;

    while ((box = trak_iter.Next()) != nullptr) {
      if (!box->Is<'mdia'>()) {
        continue;
      }

      Box::Iter mdia_iter = box->GetIter();

      while ((box = mdia_iter.Next()) != nullptr) {
        if (box->Is<'mdhd'>()) {
          struct __attribute__((packed)) MDHD {
            uint32_t version;
            uint32_t creation_time;
            uint32_t modification_time;
            uint32_t timescale;
            uint32_t duration;
          };
          const MDHD *mdhd = box->As<MDHD>();
          KRYPTON_LOGV("timescale ") << htonl(mdhd->timescale) << " duration "
                                     << htonl(mdhd->duration);
          time_scale_ = htonl(mdhd->timescale);
          duration_ = htonl(mdhd->duration);
          // duration = htonl(box->As<MDHD>()->duration);
        } else if (box->Is<'hdlr'>()) {
          struct __attribute__((packed)) HDLR {
            uint32_t reserved[2];
            uint32_t handler;
          };
          const HDLR *hdlr = box->As<HDLR>();
          if (hdlr->handler == htonl('soun')) {
            is_audio_track = true;
          }
        } else if (box->Is<'minf'>()) {
          Box::Iter minf_iter = box->GetIter();

          while ((box = minf_iter.Next()) != nullptr) {
            if (box->Is<'smhd'>()) {
              is_audio_track = true;  // found audio track
            } else if (is_audio_track && box->Is<'stbl'>()) {
              pass = ParseStbl(*box);
            }
          }
        }
      }
    }
  }

  return pass;
}

bool MP4Parser::ParseStbl(const Box &stbl) {
  Box::Iter stbl_iter = stbl.GetIter();
  const Box *box;
  bool pass = false;

  while ((box = stbl_iter.Next()) != nullptr) {
    if (box->Is<'stsd'>()) {  // sample description
      struct __attribute__((packed)) STSD {
        uint32_t _;
        uint32_t entries;
        const uint8_t data[0];
      };
      const STSD *stsd = box->As<STSD>();
      Box::Iter iter(stsd->data, 0xffffffff);

      for (uint32_t i = 0, entries = htonl(stsd->entries); i < entries; ++i) {
        box = iter.Next();

        if (box->Is<'mp4a'>()) {
          struct __attribute__((packed)) MP4A {
            uint32_t reserved[4];
            uint16_t channels;
            uint16_t sample_size;
            uint32_t reserved2;
            uint16_t sample_rate;
            uint16_t reserved3;
            Box esds;
          };
          const MP4A *mp4a = box->As<MP4A>();

          channel_count_ = htons(mp4a->channels);
          sample_bit_depth_ = htons(mp4a->sample_size);
          sample_rate_ = htons(mp4a->sample_rate);
          KRYPTON_LOGV("<#INFO#>Channel ")
              << channel_count_ << " bit " << sample_bit_depth_ << " freq "
              << sample_rate_;

          if (mp4a->esds.Is<'esds'>()) {
            pass = true;  // get adts extra data
            if (mp4a->esds.Size() >= 37) {
              adts_context.OnExtraData(mp4a->esds.Data() + 35);
            } else {
              KRYPTON_LOGE("esds box has wrong size ")
                  << mp4a->esds.Size() << ", guessing aac profile";
              adts_context.profile = 2;  // FIXME: fix profile to 2
              adts_context.channel_conf =
                  channel_count_ -
                  (channel_count_ >> 3);  // channel_conf 7 is 8
              const uint32_t rate_array[] = {
                  96000, 88200, 64000, 48000, 44100, 32000, 24000,
                  22050, 16000, 12000, 11025, 8000,  7350,
              };
              int a = 0, b = sizeof(rate_array) / sizeof(uint32_t);
              while (a < b) {
                int mid = (a + b) >> 1;
                if (rate_array[mid] == sample_rate_) {
                  adts_context.sample_rate_index = mid;
                  break;
                } else if (rate_array[mid] > sample_rate_) {
                  a = mid + 1;
                } else {
                  b = mid - 1;
                }
              }
            }
          }
        }
      }
    } else if (box->Is<'stts'>()) {  // time-to-sample table
                                     // TODO
    } else if (box->Is<'stsc'>()) {  // sample-to-chunk table
      struct __attribute__((packed)) STSC {
        uint32_t reserved;
        uint32_t entries;
        struct {
          uint32_t first_chunk;
          uint32_t samples_per_chunk;
          uint32_t sample_description_index;
        } chunks[0];
      };

      const STSC *stsc = box->As<STSC>();
      uint32_t entries = htonl(stsc->entries);
      chunks_.resize(htonl(stsc->chunks[entries - 1].first_chunk));
      Chunk *table = chunks_.data();
      uint32_t current_chunk = 0, samples_end = 0;
      for (uint32_t i = 0; i < entries - 1; i++) {
        for (uint32_t chunk_end = htonl(stsc->chunks[i + 1].first_chunk) - 1;
             current_chunk < chunk_end; current_chunk++) {
          samples_end += htonl(stsc->chunks[i].samples_per_chunk);
          table[current_chunk].samples_end = samples_end;
        }
      }
      table[current_chunk].samples_end =
          samples_end + htonl(stsc->chunks[entries - 1].samples_per_chunk);
    } else if (box->Is<'stsz'>()) {  // sample size table
      struct __attribute__((packed)) STSZ {
        uint32_t reserved;
        uint32_t sample_size;
        uint32_t sample_count;
        uint32_t sizes[0];
      };

      const STSZ *stsz = box->As<STSZ>();
      if (stsz->sample_size == 0) {  // fixed size samples
        uint32_t entries = htonl(stsz->sample_count);
        sample_sizes_.resize(entries);
        uint32_t *sizes = sample_sizes_.data();
        for (uint32_t i = 0; i < entries; i++) {
          sizes[i] = htonl(stsz->sizes[i]);
        }
      } else {
        sample_size_ = htonl(stsz->sample_size);
      }

    } else if (box->Is<'stco'>()) {  // sample chunk offset table
      struct __attribute__((packed)) STCO {
        uint32_t reserved;
        uint32_t entries;
        uint32_t offsets[0];
      };
      const STCO *stco = box->As<STCO>();
      uint32_t entries = htonl(stco->entries);

      chunks_.resize(entries);
      Chunk *table = chunks_.data();

      for (uint32_t i = 0; i < entries; i++) {
        table[i].offset = htonl(stco->offsets[i]);
      }
    }
  }

  return pass;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
