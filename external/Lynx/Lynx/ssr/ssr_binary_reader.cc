// Copyright 2022 The Lynx Authors. All rights reserved.

#include "ssr/ssr_binary_reader.h"

#include <memory>
#include <utility>

#include "base/base_export.h"
#include "lepus/context.h"
#include "lepus/debugger_base.h"
#include "lepus/function.h"
#include "lepus/heap.h"
#include "lepus/lepus_string.h"
#include "lepus/value-inl.h"

namespace lynx {
namespace lepus {

class SSRBinaryReader : public lepus::ContextBinaryReader {
 public:
  SSRBinaryReader(lepus::Context *context,
                  std::unique_ptr<lepus::InputStream> stream)
      : ContextBinaryReader(context, std::move(stream)) {}

  bool DeserializeStringSection();
};

bool SSRBinaryReader::DeserializeStringSection() {
  DECODE_U32LEB(count);
  string_list_count_ = count;
  string_list_.resize(count);
  for (size_t dd = 0; dd < count; dd++) {
    DECODE_U32LEB(length);
    if (length != 0) {
      lynx::base::scoped_refptr<lepus::StringImpl> result =
          lynx::lepus::StringImpl::Create(
              reinterpret_cast<const char *>(stream_->cursor()), length);
      stream_->Seek(stream_->offset() + length);
      string_list_[dd] = std::move(result);
    } else {
      static lepus::String kEmpty = "";
      string_list_[dd] = kEmpty;
    }
  }
  return true;
}

}  // namespace lepus

namespace ssr {
bool DecodeSSRData(std::vector<uint8_t> ssr_byte_array, lepus::Value *output) {
  // ByteArrayInputStream will keep the data.
  std::unique_ptr<lepus::ByteArrayInputStream> ssr_input =
      std::make_unique<lepus::ByteArrayInputStream>(std::move(ssr_byte_array));
  std::shared_ptr<lepus::Context> ssr_context =
      lepus::Context::CreateContext(false);

  lepus::SSRBinaryReader ssr_reader(ssr_context.get(), std::move(ssr_input));
  // A simple check sum to ensure a ssr format is received
  uint32_t ssr_data_size;
  if (!ssr_reader.ReadU32Leb128(&ssr_data_size)) {
    return false;
  }

  // The data is likely to be a proper SSR data,
  // If the data size record in first Leb128 equals to the size of the reset of
  // data. Check there is ssr_data_size of following data, and that no more
  // other data follows.
  if (!ssr_reader.CheckSize(ssr_data_size) ||
      ssr_reader.CheckSize(ssr_data_size + 1)) {
    // Check the data length
    return false;
  }

  ssr_reader.DeserializeStringSection();

  ssr_reader.DecodeValue(output);
  return true;
}

}  // namespace ssr
}  // namespace lynx
