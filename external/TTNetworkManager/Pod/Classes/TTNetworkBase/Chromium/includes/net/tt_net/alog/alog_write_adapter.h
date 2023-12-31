// Copyright (c) 2018 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_ALOG_ALOG_WRITE_ADAPTER_H
#define NET_TTNET_ALOG_ALOG_WRITE_ADAPTER_H

#include "base/logging.h"
#include "base/memory/singleton.h"
#include "base/single_thread_task_runner.h"
#include "net/tt_net/config/tt_config_manager.h"

#define ALOG_TAG "[ALOG]"
#define LEFT_BR "["
#define RIGHT_BR "]"
#define FUNCTION_TAG LEFT_BR << __FUNCTION__ << RIGHT_BR

namespace net {

#define ALOG(severity) \
  LAZY_STREAM(LOG_STREAM(severity), true) << ALOG_TAG << FUNCTION_TAG
#define VALOG(verboselevel) \
  LAZY_STREAM(VLOG_STREAM(verboselevel), true) << ALOG_TAG << FUNCTION_TAG

class ALogWriteAdapter {
 public:
  static ALogWriteAdapter* GetInstance();

  ~ALogWriteAdapter();

  typedef void (*tt_alogger_appender)(const char* file_name,
                                      const char* func_name,
                                      int line,
                                      const char* tag,
                                      int level,
                                      const char* format,
                                      ...);

  void SetALogAddress(tt_alogger_appender appender);

  void ALogWrite(const std::string& func_name,
                 int line,
                 int alog_level,
                 const std::string& log);

  static bool LogHandlerFunction(int severity,
                                 const char* file,
                                 int line,
                                 size_t message_start,
                                 const std::string& str);

 private:
  ALogWriteAdapter();
  void Write(const std::string& func_name,
             int line,
             int alog_level,
             const std::string& log);

  friend struct base::DefaultSingletonTraits<ALogWriteAdapter>;

  DISALLOW_COPY_AND_ASSIGN(ALogWriteAdapter);
};

}  // namespace net

#endif  // NET_TTNET_ALOG_ALOG_WRITE_ADAPTER_H
