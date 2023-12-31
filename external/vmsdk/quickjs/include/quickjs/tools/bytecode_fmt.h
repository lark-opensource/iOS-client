#ifndef VMSDK_QUICKJS_TOOLS_BYTECODEFMT_H
#define VMSDK_QUICKJS_TOOLS_BYTECODEFMT_H

#include <algorithm>
#include <cstdint>
#include <iostream>
#include <limits>
#include <map>
#include <vector>

#include "base_export.h"
#include "quickjs/tools/data_buffer.h"
#include "quickjs/tools/data_extractor.h"

namespace quickjs {
namespace bytecode {

enum BCShuffleMode : uint32_t {
#undef DEF
#define DEF(str, op, comment) BC_SHUFFLE_MODE_##op
#include "quickjs/tools/bytecode_shuffle_mode.inc"
#undef DEF
};

// QSMN
constexpr int32_t QUICKJS_SHUFFLE_MAGIC_NUM = 0x4E4D5351;
// QNMN
constexpr int32_t QUICKJS_NORMAL_MAGIC_NUM = 0x4E4D4E51;

// RelType ---->   offset : size
using RelType = std::pair<uint32_t, uint32_t>;

struct BCHeader {
  uint32_t magic;
  uint32_t version;
  uint32_t secNum;

  BCHeader()
      : magic(std::numeric_limits<uint32_t>::max()),
        version(std::numeric_limits<uint32_t>::max()),
        secNum(std::numeric_limits<uint32_t>::max()) {}

  bool isValid() const {
    if ((magic != QUICKJS_SHUFFLE_MAGIC_NUM) &&
        (magic != QUICKJS_NORMAL_MAGIC_NUM))
      return false;

    return version != std::numeric_limits<uint32_t>::max() &&
           secNum != std::numeric_limits<uint32_t>::max() && secNum > 0;
  }

  void write(DataBuffer &DS) {
    DS.writeUInt32(magic);
    DS.writeUInt32(version);
    DS.writeUInt32(secNum);
  }

  Status read(DataExtract &DE) {
    RETURN_IF_HAS_ERROR(DE.getUInt32(magic));
    RETURN_IF_HAS_ERROR(DE.getUInt32(version));
    RETURN_IF_HAS_ERROR(DE.getUInt32(secNum));
    return Status::OK();
  }
};

enum class SecType : uint32_t {
  ST_JS_BYTECODE = 0x0001,
  ST_SECNAME = 0x0010,
  ST_VERSION = 0x0100,
  ST_SHUFFLE = 0x1000,
  ST_MAX_COUNT
};

struct BCSection {
  SecType secType;
  uint32_t offset;
  uint32_t secSize;

  static const uint32_t INVALID_NUM;

  BCSection()
      : secType(SecType::ST_MAX_COUNT),
        offset(INVALID_NUM),
        secSize(INVALID_NUM) {}

  BCSection(SecType secType, uint32_t offset, uint32_t secSize)
      : secType(secType), offset(offset), secSize(secSize) {}

  bool isValid() const {
    return (secType != SecType::ST_MAX_COUNT) && (secSize != INVALID_NUM);
  }

  void write(DataBuffer &DS, std::vector<RelType> &secRels) {
    // #ifndef EMSCRIPTEN
    //     assert(isValid() && "BCSection is not valid");
    // #endif

    // 1. write fields
    DS.writeUInt32((uint32_t)secType);
    auto result = DS.writeUInt32(offset);
    DS.writeUInt32(secSize);

    // 2. save repatch point
    secRels.push_back(std::make_pair(result.second, sizeof(uint32_t)));
  }

  Status read(DataExtract &DE) {
    uint32_t type = -1U;
    RETURN_IF_HAS_ERROR(DE.getUInt32(type));
    secType = (SecType)type;
    RETURN_IF_HAS_ERROR(DE.getUInt32(offset));
    RETURN_IF_HAS_ERROR(DE.getUInt32(secSize));
    return Status::OK();
  }
};

struct BCRWConfig {
  uint32_t version;
  uint32_t shuffleNo;
  BCShuffleMode shuffleMode;
  std::vector<uint32_t> shuffleArgs;

  BCRWConfig()
      : version(-1U),
        shuffleNo(BC_SHUFFLE_MODE_INVALID),
        shuffleMode((BCShuffleMode)shuffleNo) {}
  BCRWConfig(uint32_t version, uint32_t shuffleNo)
      : version(version),
        shuffleNo(shuffleNo),
        shuffleMode((BCShuffleMode)shuffleNo) {}

  uint32_t calcSz() const {
    uint32_t sz = sizeof(uint32_t) * 3;
    sz += sizeof(uint32_t) * shuffleArgs.size();
    sz += 8;
    return sz;
  }

  bool write(DataBuffer &DS) {
    DS.writeUInt32(version);
    DS.writeUInt32(shuffleNo);
    DS.writeUInt32((uint32_t)shuffleArgs.size());

    for (auto iter : shuffleArgs) DS.writeUInt32(iter);

    return true;
  }

  Status read(DataExtract &DE) {
    RETURN_IF_HAS_ERROR(DE.getUInt32(version));
    RETURN_IF_HAS_ERROR(DE.getUInt32(shuffleNo));
    shuffleMode = (BCShuffleMode)shuffleNo;

    uint32_t len = 0;
    RETURN_IF_HAS_ERROR(DE.getUInt32(len));
    for (uint32_t idx = 0; idx < len; idx++) {
      uint32_t value;
      RETURN_IF_HAS_ERROR(DE.getUInt32(value));
      shuffleArgs.push_back(value);
    }
    return Status::OK();
  }

  // ---- wasm binding start ---
  uint32_t getVersion() const { return version; }
  void setVersion(uint32_t value) { version = value; }

  uint32_t getShuffleNo() const { return shuffleNo; }
  void setShuffleNo(uint32_t value) {
    shuffleNo = value;
    shuffleMode = (BCShuffleMode)value;
  }

  std::vector<uint32_t> getShuffleArgs() const { return shuffleArgs; }
  void addValue(uint32_t value) { shuffleArgs.push_back(value); }
  // ---- wasm binding end ---
};

struct BCFmt {
  BCHeader header;
  std::vector<BCSection> sections;
  std::vector<std::string> secContents;
  std::vector<RelType> secRels;

  BCFmt() = default;
  BCFmt(BCHeader &header, std::vector<BCSection> &sections,
        std::vector<std::string> &secContents)
      : header(header),
        sections(std::move(sections)),
        secContents(std::move(secContents)) {}

  Status getConfig(BCRWConfig &result) {
    for (uint64_t idx = 0; idx < sections.size(); idx++)
      if (sections[idx].secType == SecType::ST_SHUFFLE) {
        DataBuffer DB(secContents[idx]);
        DataExtract DE(DB);
        return result.read(DE);
      }
    return Status(ERR_FAILED_TO_GET_CONF, "failed to get confg");
  }

  std::string getBinaryCode() const {
    uint64_t idx = -1UL;
    for (uint64_t i = 0; i < sections.size(); i++)
      if (sections[i].secType == SecType::ST_JS_BYTECODE) {
        idx = i;
        break;
      }
    if (idx == -1UL) return "";
    return secContents[idx];
  }

  bool isValid() const {
    if (!header.isValid() || sections.size() == 0 ||
        (sections.size() != secContents.size()))
      return false;

    if (std::any_of(sections.begin(), sections.end(),
                    [](BCSection sec) { return !sec.isValid(); }))
      return false;

    if (std::any_of(secContents.begin(), secContents.end(),
                    [](std::string content) { return content.empty(); }))
      return false;

    return true;
  }

  uint32_t calcSz() {
    uint32_t size = sizeof(BCHeader);
    for (const BCSection &sec : sections) {
      size += sizeof(BCSection);
      size += sec.secSize;
    }
    return size;
  }

  Status read(DataExtract &DE) {
    RETURN_IF_HAS_ERROR(header.read(DE));
    for (uint32_t idx = 0; idx < header.secNum; idx++) {
      BCSection Sec;
      RETURN_IF_HAS_ERROR(Sec.read(DE));
      // #ifndef EMSCRIPTEN
      //       assert(DE.isValid() && "data extraction should be valid");
      // #endif
      sections.emplace_back(Sec);
    }

    for (uint32_t idx = 0; idx < header.secNum; idx++) {
      std::string result = "";
      RETURN_IF_HAS_ERROR(DE.getString(sections[idx].secSize, result));
      secContents.push_back(result);
    }
    // #ifndef EMSCRIPTEN
    //     assert(isValid() && "BCHeader should be valid");
    // #endif
    return Status::OK();
  }

  bool write(DataBuffer &DS) {
    // #ifndef EMSCRIPTEN
    //     assert(isValid() && "BCFmt is not valid");
    // #endif
    header.write(DS);

    for (BCSection &sec : sections) sec.write(DS, secRels);

    if (secRels.size() == 0 || (secRels.size() != sections.size()))
      return false;

    uint64_t idx = 0;
    for (const std::string &Content : secContents) {
      // 1. write content to memory buffer
      auto Info = DS.writeString(Content);

      // 2. repatch section header
      *(uint32_t *)(DS.getRawData() + secRels[idx].first) =
          (uint32_t)Info.second;

      idx++;
    }

    return true;
  }
};

}  // namespace bytecode
}  // namespace quickjs

#endif
