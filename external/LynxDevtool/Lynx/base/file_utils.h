// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_FILE_UTILS_H_
#define LYNX_BASE_FILE_UTILS_H_

#include <string>

namespace lynx {
namespace base {

class FileUtils {
 public:
  [[nodiscard]] static bool ReadFileBinary(const std::string &path,
                                           size_t max_size,
                                           std::string &file_content);
  [[nodiscard]] static bool WriteFileBinary(const std::string &path,
                                            const unsigned char *file_content,
                                            size_t size);
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_FILE_UTILS_H_
