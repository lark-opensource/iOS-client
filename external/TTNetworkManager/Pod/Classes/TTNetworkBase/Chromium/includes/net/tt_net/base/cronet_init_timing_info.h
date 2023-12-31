// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_CRONET_INIT_TIMING_INFO_H
#define NET_TT_NET_BASE_CRONET_INIT_TIMING_INFO_H

#include <stdint.h>

#include "net/base/net_export.h"

namespace net {

struct TTNET_IMPLEMENT_EXPORT NET_EXPORT CronetInitTimingInfo {
  CronetInitTimingInfo();
  ~CronetInitTimingInfo();

  // The java utc time when the context starts/ends initializing on init thread.
  int64_t init_thread_start{-1};
  int64_t init_thread_end{-1};

  // The java utc time when the context starts/ends initializing on network
  // thread.
  int64_t network_thread_init_start{-1};
  int64_t network_thread_init_end{-1};

  // The java utc time when the module starts/ends initializing on network
  // thread.
  int64_t nqe_init_start{-1};
  int64_t nqe_init_end{-1};

  int64_t prefs_init_start{-1};
  int64_t prefs_init_end{-1};

  int64_t channel_init_start{-1};
  int64_t channel_init_end{-1};

  int64_t context_builder_start{-1};
  int64_t context_builder_end{-1};

  int64_t tnc_config_init_start{-1};
  int64_t tnc_config_init_end{-1};

  int64_t update_appinfo_start{-1};
  int64_t update_appinfo_end{-1};

  int64_t netlog_init_start{-1};
  int64_t netlog_init_end{-1};

  int64_t nqe_detect_init_start{-1};
  int64_t nqe_detect_init_end{-1};

  int64_t preconnect_init_start{-1};
  int64_t preconnect_init_end{-1};

  int64_t ssl_session_init_start{-1};
  int64_t ssl_session_init_end{-1};

  int64_t ttnet_config_init_start{-1};
  int64_t ttnet_config_init_end{-1};

  int64_t install_cert_init_start{-1};
  int64_t install_cert_init_end{-1};

  // The java utc time when the context starts/ends executing tasks on network
  // thread.
  int64_t execute_waiting_task_start{-1};
  int64_t execute_waiting_task_end{-1};
};

}  // namespace net

#endif  // NET_TT_NET_BASE_CRONET_INIT_TIMING_INFO_H
