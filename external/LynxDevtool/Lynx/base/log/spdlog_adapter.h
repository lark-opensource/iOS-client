// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_BASE_LOG_SPDLOG_ADAPTER_H_
#define LYNX_BASE_LOG_SPDLOG_ADAPTER_H_

#include <memory>
#include <string>

#include "base/log/logging.h"
#include "spdlog/spdlog.h"

namespace lynx {
namespace base {
namespace logging {

class SpdlogAdapter : public LoggingDelegate {
 public:
  explicit SpdlogAdapter(const std::string& log_path);
  void Log(LogMessage* msg) override;

 private:
  std::unique_ptr<spdlog::logger> logger_;
};

}  // namespace logging
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_LOG_SPDLOG_ADAPTER_H_
