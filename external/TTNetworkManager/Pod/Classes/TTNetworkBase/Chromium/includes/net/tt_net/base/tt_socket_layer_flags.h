// Copyright (c) 2021 The Bytedance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_TT_SOCKET_LAYER_FLAGS_H_
#define NET_TT_NET_BASE_TT_SOCKET_LAYER_FLAGS_H_

namespace net {

enum {

#define TT_SO_FLAG(label, value) TT_SO_FLAG_##label = value,
#include "net/tt_net/base/tt_socket_layer_flags_list.h"
#undef TT_SO_FLAG

};

}  // namespace net

#endif  // NET_TT_NET_BASE_TT_SOCKET_LAYER_FLAGS_H_