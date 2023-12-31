//
// Created by lynx on 2021/7/9.
//

/**
 * this file for time different interface and struct in different platform
 */
#ifndef LYNX_LEPUS_TT_TM_H_
#define LYNX_LEPUS_TT_TM_H_
namespace lynx {
namespace lepus {

void GetTimeZone(tm_extend& tm);

#if defined(OS_WIN)
#include <windows.h>
#include <winsock.h>

// struct timeval defines in winsock.h of MSVC
int gettimeofday(struct timeval* tp, void* tzp) {
  std::chrono::system_clock::duration d =
      std::chrono::system_clock::now().time_since_epoch();
  std::chrono::seconds s = std::chrono::duration_cast<std::chrono::seconds>(d);
  tp->tv_sec = s.count();
  tp->tv_usec =
      std::chrono::duration_cast<std::chrono::microseconds>(d - s).count();
  return 0;
}

#define timegm _mkgmtime

#define localtime_r(T, Tm) localtime_s(Tm, T)

#define gmtime_r(T, Tm) gmtime_s(Tm, T)

void GetTimeZone(tm_extend& tm) {
  const bool is_dst = tm.tm_isdst > 0;
  _get_timezone(&tm.tm_gmtoff);
  long dstbias;
  _get_dstbias(&dstbias);
  tm.tm_gmtoff = tm.tm_gmtoff + (is_dst ? dstbias : 0);
}

#else  // other platform
void GetTimeZone(tm_extend& tm) {
  // do nothing
}

#endif  // OS_WIN
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_TT_TM_H_
