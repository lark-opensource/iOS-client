
#ifndef NET_TTNET_THROTTLE_THROTTLE_H_
#define NET_TTNET_THROTTLE_THROTTLE_H_

#include "base/timer/timer.h"
#include "net/base/completion_once_callback.h"
#include "net/net_buildflags.h"

namespace net {

class Throttle {
 public:
  Throttle(int64_t bytesPerSecond,
           bool is_chunked = false,
           bool force_delay_upload_enabled = false);
  ~Throttle();
  int DoThrottle(const int readBytes, base::OnceClosure closure);
  // unit is Byte
  void SetNetSpeed(int64_t netSpeedBytes);
  int64_t GetThrottleValue() const;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  int64_t GetCurrReceiveBytesForTesting() const;
  void DoWhenTimeoutForTesting();
#endif
  void SetFileSize(const uint64_t file_size);

 private:
  void DoWhenTimeout();
  void ResetTimer(int64_t time);
  base::RepeatingTimer speed_control_timer_;
  base::OnceClosure closure_;
  int64_t allow_bytes_per_cycle_{0};
  int64_t curr_receive_bytes_{0};
  uint64_t file_size_{0};
  bool is_chunked_{false};
  bool skip_throttle_{false};
  bool force_delay_upload_enabled_{false};
  const bool high_accuracy_mode_{false};
  const int timer_reset_duration_{1000};
};
}  // namespace net
#endif
