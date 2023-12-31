// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_QUIC_PLATFORM_IMPL_QUIC_ESTIMATE_MEMORY_USAGE_IMPL_H_
#define NET_QUIC_PLATFORM_IMPL_QUIC_ESTIMATE_MEMORY_USAGE_IMPL_H_

#include <cstddef>

#include "base/trace_event/memory_usage_estimator.h"
#include "base/ttnet_implement_buildflags.h"

#if BUILDFLAG(TTNET_IMPLEMENT)
#include "base/tracing_buildflags.h"
#endif

namespace quic {

template <class T>
size_t QuicEstimateMemoryUsageImpl(const T& object) {
#if BUILDFLAG(ENABLE_BASE_TRACING)
  return base::trace_event::EstimateMemoryUsage(object);
#else
  return 0;
#endif
}

}  // namespace quic

#endif  // NET_QUIC_PLATFORM_IMPL_QUIC_ESTIMATE_MEMORY_USAGE_IMPL_H_
