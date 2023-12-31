//
//  mem_lru_net_log_observer.h
//  sources
//
//  Created by gaohaidong on 2018/8/8.
//

#ifndef mem_lru_net_log_observer_h
#define mem_lru_net_log_observer_h

#include <deque>
#include <memory>

#include "base/macros.h"
#include "base/values.h"
#include "net/base/net_export.h"
#include "net/log/net_log.h"
#include "net/net_buildflags.h"

namespace base {
class Value;
}

namespace net {

class URLRequestContext;

class NET_EXPORT MemLruNetLogObserver : public NetLog::ThreadSafeObserver {
 public:
  MemLruNetLogObserver();

  ~MemLruNetLogObserver() override;

  void OnAddEntry(const NetLogEntry& entry) override;

  void SetCacheLimit(size_t size) { cache_limit_ = size; }

  void StartObserving(URLRequestContext* url_request_context,
                      NetLog* net_log,
                      NetLogCaptureMode capture_mode);

  void StopObserving(URLRequestContext* url_request_context);

  std::string GetRecentNetLogJson();

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class NetLogManagerTest;
  friend class NetLogManagerTestByMockTime;
  friend class NetLogManagerTestFunction;
#endif
  std::deque<std::unique_ptr<base::Value>> values_;
  size_t cache_limit_{1000};
  URLRequestContext* url_request_context_{nullptr};

  DISALLOW_COPY_AND_ASSIGN(MemLruNetLogObserver);
};

}  // namespace net

#endif /* mem_lru_net_log_observer_h */
