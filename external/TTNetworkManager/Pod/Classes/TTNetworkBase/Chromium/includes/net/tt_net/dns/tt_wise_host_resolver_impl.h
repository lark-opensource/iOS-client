// Copyright (c) 2018 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_DNS_TT_WISE_HOST_RESOLVER_IMPL_H_
#define NET_TT_NET_DNS_TT_WISE_HOST_RESOLVER_IMPL_H_

#include <stddef.h>
#include <stdint.h>

#include <map>
#include <memory>

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/strings/string_piece.h"
#include "base/threading/thread_checker.h"
#include "base/time/time.h"
#include "base/timer/timer.h"
#include "net/base/net_export.h"
#include "net/base/network_change_notifier.h"
#include "net/dns/dns_config_service.h"
#include "net/dns/host_cache.h"
#include "net/dns/host_resolver.h"
#include "net/tt_net/dns/tt_dns_service_provider_observer.h"

namespace net {

class AddressList;
class DnsClient;
class CustomizedDnsServiceProvider;
class DnsServiceProviderBase;
class DirectDnsServiceProvider;
class FinalBackupDnsServiceProvider;
class LocalDnsServiceProvider;
class HttpDnsServiceProvider;
class IPAddress;
class NetLog;
class NetLogWithSource;
class PrioritizedDispatcher;
class TTWiseResolverStrategy;
struct HostResolverConfig;

enum DnsServiceProviderType {
  SYSTEM_LOCAL_DNS_SERVICE,
  CUSTOMIZED_ASYNC_DNS_SERVICE,
  HTTP_DNS_SERVICE,
  DNS_SERVICE_TYPE_LAST = HTTP_DNS_SERVICE,
  // These two are internal built-in types, not controlled by config.
  DIRECT_RESOLVE_DNS_SERVICE,
  FINAL_BACKUP_DNS_SERVICE
};

enum DnsServiceTrustLevel {
  NOT_USED = -1,
  TL0,
  TL1,
  TL2,
  TL3,
  TL4,
  TL5,
  TL6,
  TL7,
  TL8,
  TL9,
  TL_MAX = TL9
};

enum HostResolverWorkingMode {
  WORKING_MODE_NOT_IMPL,
  COCURRENT,
  SEQUENTIAL,
  CACHE_FIRST_SEQUENTIAL,
  WORKING_MODE_LAST = CACHE_FIRST_SEQUENTIAL
};

/* lonnie

// For each hostname that is requested, HostResolver creates a
// HostResolverImpl::Job. When this job gets dispatched it creates a ProcTask
// which runs the given HostResolverProc on a worker thread (a WorkerPool
// thread, in production code.) If requests for that same host are made during
// the job's lifetime, they are attached to the existing job rather than
// creating a new one. This avoids doing parallel resolves for the same host.
//
// The way these classes fit together is illustrated by:
//
//
//            +----------- HostResolverImpl -------------+
//            |                    |                     |
//           Job                  Job                   Job
//    (for host1, fam1)    (for host2, fam2)     (for hostx, famx)
//       /    |   |            /   |   |             /   |   |
//   Request ... Request  Request ... Request   Request ... Request
//  (port1)     (port2)  (port3)      (port4)  (port5)      (portX)
//
// When a HostResolverImpl::Job finishes, the callbacks of each waiting request
// are run on the origin thread.
//
// Thread safety: This class is not threadsafe, and must only be called
// from one thread!
//
// The HostResolverImpl enforces limits on the maximum number of concurrent
// threads using PrioritizedDispatcher::Limits.
//
// Jobs are ordered in the queue based on their priority and order of arrival.
//
// To implement asynchronous dns query, each Job who gets a stale or null result
// will trigger some DnsQueryJobs according to strategy. Each DnsQueryJob will
// bind to one real query task to implement dns query, and each DnsQueryJob
// belongs
// to a particular DnsServiceProvider. The result of the DnsQueryJob will be
// saved
// into the cache of DnsServiceProvider and returned to Job.
//
// The way these classes fit together is illustrated by:
//
//                                 |
//            +------------------ Job1 ------------------+
//            |            (for host1, fam1)             |
//            |                    |                     |
//    DnsServiceProvider1  DnsServiceProvider2   DnsServiceProviderX
//       /    |   \                |                /    |      |
//    Dns         Dns                            Dns           Dns
//  QueryJob ... QueryJob         ...         QueryJob  ...  QueryJob
// (for Job1)  (for other jobs)              (for Job1)    (for other jobs)
//     |            |                             |             |
//  DnsTask  ... DnsTask                       DnsTask  ...  DnsTask
class NET_EXPORT TTWiseHostResolverImpl
    : public HostResolver,
      public NetworkChangeNotifier::IPAddressObserver,
      public NetworkChangeNotifier::DNSObserver,
      public DnsServiceProviderObserver {
 public:
  class Job;

  enum State {
    STATE_DIRECT_RESOLVE,
    STATE_LOOKUP_CACHE,
    STATE_START_ASYNC_QUERY_TASK,
    STATE_WAIT_FOR_QUERY_TASK,
    STATE_DECIDE_CONTINUE_TO_WAIT,
    STATE_WAIT_FOR_QUERY_TASK_COMPLETE,
    STATE_LOOKUP_BACKUP_CACHE,
    STATE_NONE
  };

  // Creates a HostResolver as specified by |options|. Blocking tasks are run on
  // the WorkerPool.
  //
  // If Options.enable_caching is true, a cache is created using
  // HostCache::CreateDefaultCache(). Otherwise no cache is used.
  //
  // Options.GetDispatcherLimits() determines the maximum number of jobs that
  // the resolver will run at once. This upper-bounds the total number of
  // outstanding DNS transactions (not counting retransmissions and retries).
  //
  // |net_log| must remain valid for the life of the HostResolverImpl.
  TTWiseHostResolverImpl(const ManagerOptions& options, NetLog* net_log);

  // If any completion callbacks are pending when the resolver is destroyed,
  // the host resolutions are cancelled, and the completion callbacks will not
  // be called.
  ~TTWiseHostResolverImpl() override;

  // HostResolver methods:
  int Resolve(const RequestInfo& info,
              RequestPriority priority,
              AddressList* addresses,
              const CompletionCallback& callback,
              std::unique_ptr<Request>* out_req,
              const NetLogWithSource& source_net_log) override;
  int ResolveFromCache(const RequestInfo& info,
                       AddressList* addresses,
                       const NetLogWithSource& source_net_log) override;
  void RemoveCacheEntry(const RequestInfo& info, int dns_source) override;

  void SetHttpDnsEnabled(bool enabled,
                         URLRequestContextGetter* context_getter) override;

  HostCache* GetHostCache() override;

  void GetCurrentDnsConfig(DnsConfig& dns_config) const override;

  // Avoid to include in loop, consistent with
  // TTWiseResolverStrategy::ServiceSequenceIterator.
  using ServiceSequenceIterator = std::list<DnsServiceProviderBase*>::iterator;
  ServiceSequenceIterator GetServiceSequenceIterator() const;

  TTWiseResolverStrategy* strategy() const { return strategy_.get(); }

  DirectDnsServiceProvider* direct_dns_service_provider() const {
    return direct_dns_service_provider_.get();
  }
  LocalDnsServiceProvider* local_dns_service_provider() const {
    return local_dns_service_provider_.get();
  }
  CustomizedDnsServiceProvider* customized_dns_service_provider() const {
    return customized_dns_service_provider_.get();
  }
  HttpDnsServiceProvider* http_dns_service_provider() const {
    return http_dns_service_provider_.get();
  }
  FinalBackupDnsServiceProvider* final_backup_dns_service_provider() const {
    return final_backup_dns_service_provider_.get();
  }

 private:
  class RequestImpl;
  using Key = HostCache::Key;
  using Entry = HostCache::Entry;
  using JobMap = std::map<Key, std::unique_ptr<Job>>;

  // Returns the (hostname, address_family) key to use for |info|, choosing an
  // "effective" address family by inheriting the resolver's default address
  // family when the request leaves it unspecified.
  Key GetEffectiveKeyForRequest(const RequestInfo& info,
                                const NetLogWithSource& net_log);

  // Removes |job| from |jobs_|, only if it exists, but does not delete it.
  void RemoveJob(Job* job);

  // Aborts all in progress jobs with ERR_NETWORK_CHANGED and notifies their
  // requests. Might start new jobs.
  void AbortAllInProgressJobs();

  // NetworkChangeNotifier::IPAddressObserver:
  void OnIPAddressChanged() override;

  // NetworkChangeNotifier::DNSObserver:
  void OnDNSChanged() override;
  void OnInitialDNSConfigRead() override;

  void UpdateDNSConfig(bool config_changed);

  // DnsServiceProviderObserver:
  void OnNewEntryAdded(const Key& key, const Entry& entry) override;

  // Map from HostCache::Key to a Job.
  JobMap jobs_;

  // Starts Jobs according to their priority and the configured limits.
  std::unique_ptr<PrioritizedDispatcher> dispatcher_;

  // Limit on the maximum number of jobs queued in |dispatcher_|.
  size_t max_queued_jobs_;

  NetLog* net_log_;

  // Preserve current dns config copy for network thread logic to access,
  // because the NetworkChangeNotifier::GetDnsConfig call uses lock to be
  // thread-safe but slow down function call.
  // Note that we did not copy dns config from hosts file, which is not a
  // necessary information.
  DnsConfig current_dns_config_;

  const HostResolverConfig* ttnet_dns_config_;

  std::unique_ptr<DirectDnsServiceProvider> direct_dns_service_provider_;

  std::unique_ptr<LocalDnsServiceProvider> local_dns_service_provider_;

  std::unique_ptr<CustomizedDnsServiceProvider>
      customized_dns_service_provider_;

  std::unique_ptr<HttpDnsServiceProvider> http_dns_service_provider_;

  std::unique_ptr<FinalBackupDnsServiceProvider>
      final_backup_dns_service_provider_;

  std::unique_ptr<TTWiseResolverStrategy> strategy_;

  THREAD_CHECKER(thread_checker_);

  base::WeakPtrFactory<TTWiseHostResolverImpl> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(TTWiseHostResolverImpl);
};
*/
}  // namespace net

#endif  // NET_TT_NET_DNS_TT_WISE_HOST_RESOLVER_IMPL_H_
