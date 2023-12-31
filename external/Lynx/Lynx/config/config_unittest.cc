/* Copyright 2021 The Lynx Authors. All rights reserved. */

#include "config/config.h"

#include "gtest/gtest.h"

namespace lynx {
namespace config {
namespace testing {

TEST(ConfigTest, checkDefintions) {
  // FIXME(zhongxiao.yzx): check features according to definitions
#if defined(ENABLE_LITE)
  EXPECT_TRUE(true);
#endif
}

}  // namespace testing
}  // namespace config
}  // namespace lynx
