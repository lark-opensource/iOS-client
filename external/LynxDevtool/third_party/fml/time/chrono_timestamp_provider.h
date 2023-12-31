// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_TIME_CHRONO_TIMESTAMP_PROVIDER_H_
#define THIRD_PARTY_FLUTTER_FML_TIME_CHRONO_TIMESTAMP_PROVIDER_H_

#include "third_party/fml/macros.h"
#include "third_party/fml/time/time_point.h"
#include "third_party/fml/time/timestamp_provider.h"

namespace lynx {
namespace fml {

/// TimestampProvider implementation that is backed by std::chrono::steady_clock
/// meant to be used only in tests for `fml`. Other components needing the
/// current time ticks since epoch should instantiate their own time stamp
/// provider backed by Dart clock.
class ChronoTimestampProvider : TimestampProvider {
 public:
  static ChronoTimestampProvider& Instance() {
    static ChronoTimestampProvider instance;
    return instance;
  }

  ~ChronoTimestampProvider() override;

  fml::TimePoint Now() override;

 private:
  ChronoTimestampProvider();

  FML_DISALLOW_COPY_AND_ASSIGN(ChronoTimestampProvider);
};

fml::TimePoint ChronoTicksSinceEpoch();

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_TIME_CHRONO_TIMESTAMP_PROVIDER_H_
