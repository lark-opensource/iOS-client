// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_BASE_PATHS_WIN_H_
#define LYNX_BASE_PATHS_WIN_H_
#include <string>
#include <utility>

namespace lynx {
namespace base {
std::pair<bool, std::string> GetExecutableDirectoryPath();
bool DirectoryExists(const std::string& path);
std::string JoinPaths(std::initializer_list<std::string> components);
bool CreateDir(const std::string& path);
bool GetFileSize(const std::string& file_path, int64_t& file_size);
}  // namespace base
}  // namespace lynx
#endif  // LYNX_BASE_PATHS_WIN_H_
