// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LEPUS_CMD_H_
#define LYNX_TASM_LEPUS_CMD_H_
#ifndef __EMSCRIPTEN__

#include <fts.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <string>

#include "lepus/json_parser.h"
#include "rapidjson/document.h"
#include "rapidjson/error/en.h"
#include "rapidjson/reader.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

namespace lynx {
namespace lepus_cmd {
struct PackageConfigs {
  bool snapshot_;
  bool silence_;
  bool enable_radon_;
  std::string target_sdk_version_;
};
std::string MakeEncodeOptions(const std::string& abs_folder_path,
                              const std::string& ttml_file_path,
                              const PackageConfigs& package_configs);
std::string MakeEncodeOptionsFromArgs(int argc, char** argv);
}  // namespace lepus_cmd
}  // namespace lynx

#endif  //__EMSCRIPTEN__

#endif  // LYNX_TASM_LEPUS_CMD_H_
