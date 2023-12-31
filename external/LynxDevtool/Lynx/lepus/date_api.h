#ifndef LYNX_LEPUS_DATE_API_H_
#define LYNX_LEPUS_DATE_API_H_

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG

#include <time.h>

#include <chrono>

namespace lynx {
namespace lepus {
Value Now(Context* context) {
  using std::chrono::milliseconds;
  using std::chrono::system_clock;
  using std::chrono::time_point;
  using std::chrono::time_point_cast;
  using time_stamp = time_point<system_clock, milliseconds>;
  time_stamp tp = time_point_cast<milliseconds>(system_clock::now());
  auto current_time = tp.time_since_epoch().count();

  return Value((uint64_t)current_time);
}

void RegisterDateAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "now", &Now);
  RegisterBuiltinFunctionTable(ctx, "Date", table);
}
}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_DATE_API_H_
