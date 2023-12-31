// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_BASE_FILE_STREAM_H_
#define LYNX_DEVTOOL_BASE_FILE_STREAM_H_

#include <fstream>
#include <map>

namespace lynxdev {
namespace devtool {

class FileStream {
 public:
  FileStream() = delete;
  static int Open(const std::string& file,
                  std::ios::openmode mode = std::ios::in);
  static void Close(int handle);
  static int Read(int handle, char* buf, size_t size);
  static int Read(int handle, std::ostream& oss, size_t size);

 private:
  static std::map<int, std::unique_ptr<std::fstream>> streams_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_BASE_FILE_STREAM_H_
