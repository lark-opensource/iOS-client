// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_TIME_TIMESTAMP_PROVIDER_H_
#define THIRD_PARTY_FLUTTER_FML_TIME_TIMESTAMP_PROVIDER_H_

#include <cstdint>

#include "third_party/fml/time/time_point.h"

namespace lynx {
namespace fml {

/// Pluggable provider of monotonic timestamps. Invocations of `Now` must return
/// unique values. Any two consecutive invocations must be ordered.
class TimestampProvider {
 public:
  virtual ~TimestampProvider(){};

  // Returns the number of ticks elapsed by a monotonic clock since epoch.
  virtual fml::TimePoint Now() = 0;
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_TIME_TIMESTAMP_PROVIDER_H_
