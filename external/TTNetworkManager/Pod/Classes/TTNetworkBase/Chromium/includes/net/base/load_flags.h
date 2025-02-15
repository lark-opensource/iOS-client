// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_BASE_LOAD_FLAGS_H_
#define NET_BASE_LOAD_FLAGS_H_

#include "base/ttnet_implement_buildflags.h"

namespace net {

// These flags provide metadata about the type of the load request.  They are
// intended to be OR'd together.
enum {

#define LOAD_FLAG(label, value) LOAD_ ## label = value,
#include "net/base/load_flags_list.h"
#undef LOAD_FLAG

};

}  // namespace net

#endif  // NET_BASE_LOAD_FLAGS_H_
