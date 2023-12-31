// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SSR_BINARY_WRITER_H_
#define LYNX_SSR_SSR_BINARY_WRITER_H_

#include "lepus/context_binary_writer.h"
#include "tasm/compile_options.h"

namespace lynx {
namespace lepus {

class SSRBinaryWriter : public lepus::ContextBinaryWriter {
 public:
  SSRBinaryWriter(Context* context,
                  const tasm::CompileOptions& compile_options = {});
  void SerializeStringTable();
  void CreateCheckSum();
};

}  // namespace lepus
}  // namespace lynx
#endif  // LYNX_SSR_SSR_BINARY_WRITER_H_
