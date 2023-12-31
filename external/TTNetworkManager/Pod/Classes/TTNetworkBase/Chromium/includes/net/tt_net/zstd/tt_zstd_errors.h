// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_ZSTD_ERRORS_H
#define NET_TT_NET_ZSTD_ERRORS_H

namespace net {

enum ZSTDError {
#define ZSTD_ERROR(label, value) ERR_ZSTD_##label = value,
#include "net/tt_net/zstd/tt_zstd_error_list.h"
#undef ZSTD_ERROR
};

}  // namespace net

#endif  // NET_TT_NET_ZSTD_ERRORS_H