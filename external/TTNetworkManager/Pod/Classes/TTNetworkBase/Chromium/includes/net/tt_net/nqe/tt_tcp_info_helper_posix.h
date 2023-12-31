// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_TCP_INFO_HELPER_POSIX_H_
#define NET_TT_NET_NQE_TT_TCP_INFO_HELPER_POSIX_H_

#include <stdint.h>

#include "net/tt_net/nqe/tt_tcp_info_helper.h"

namespace net {

class TTTCPInfoHelperPosix : public TTTCPInfoHelper {
 public:
  TTTCPInfoHelperPosix();
  ~TTTCPInfoHelperPosix() override;

 private:
  bool UpdateTCPInfo() override;
};

}  // namespace net

#endif