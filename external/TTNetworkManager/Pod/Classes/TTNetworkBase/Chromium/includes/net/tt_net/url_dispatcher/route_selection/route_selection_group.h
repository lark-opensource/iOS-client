// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_ROUTE_SELECTION_GROUP_H_
#define NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_ROUTE_SELECTION_GROUP_H_

#include <map>
#include <memory>
#include <vector>

#include "base/memory/weak_ptr.h"
#include "base/values.h"
#include "net/base/completion_once_callback.h"
#include "net/http/http_response_headers.h"
#include "net/net_buildflags.h"
#include "url/scheme_host_port.h"

namespace net {

constexpr char kRouteTestRequestPath[] = "/ies/speed/";

constexpr char kDsaEdgeRouteTestRequestPath[] = "/ttnet/dsa/speed/";

constexpr char kCachePrefix[] = "ttdispatch";

struct RouteTestResult {
  int result;
  std::vector<base::Callback<void(int, int, bool)>> pending_callbacks;

  RouteTestResult();
  RouteTestResult(int test_result);
  RouteTestResult(const RouteTestResult&);
  ~RouteTestResult();
};

// key is scheme + host + path.
using RouteTestResultTable = std::map<GURL, RouteTestResult>;

enum WorkingMode {
  UNKNOWN = 0,
  CONCURRENT_ROUTE_SELECTION = 1,
  SEQUENTIAL_ROUTE_SELECTION = 2,
  FUSION_BASED_ROUTE_SELECTION = 3
};

enum SchemeOption {
  MASK_PRESERVE = 1,
  HTTPS_ENABLE = 1 << 1,
  HTTP_ENABLE = 1 << 2,
  SCHEME_OPTION_LAST = HTTP_ENABLE
};

class RouteSelectionGroup {
 public:
  struct RouteCandidate {
    RouteCandidate();
    RouteCandidate(const std::string& route_host,
                   int id,
                   int route_weight,
                   int route_threshold,
                   double route_server_score);
    RouteCandidate(const RouteCandidate&);
    ~RouteCandidate();

    // Allows RouteCandidate to be used as a key in STL (for example, a std::set
    // or std::map).
    bool operator<(const RouteCandidate& other) const;

    // Original host parsed from TNC config.
    std::string host;
    // Final host dispatched by URL-Dispatcher module.
    std::string final_host;
    // Flag to accelerate sending /ies/speed/ request for next candidate on
    // serial mode.
    mutable bool current_route_test_completed_;
    int id;
    int weight;
    int threshold;
    double server_score;
  };

  static std::unique_ptr<RouteSelectionGroup> Factory(
      const std::vector<RouteCandidate>& candidates_info,
      WorkingMode working_mode,
      int scheme_option,
      const std::string& sign,
      const int64_t epoch,
      unsigned int priority,
      const base::DictionaryValue* extra_strategy_info,
      bool dsa_edge_route);

  RouteSelectionGroup(const std::vector<RouteCandidate>& candidates_info,
                      int scheme_option,
                      const std::string& sign,
                      const int64_t epoch,
                      unsigned int priority,
                      bool dsa_edge_route);
  virtual ~RouteSelectionGroup();

  void StartRouteSelection(CompletionOnceCallback callback,
                           bool can_use_global_route_test_result);

  const url::SchemeHostPort& GetBestTargetOfGroup();

  void SetBestHost(const std::string& host);

  int RecordBestTargetFailure();

  void SetGlobalRouteTestResultTableReference(
      RouteTestResultTable* route_test_result_table_ref);

  size_t size() const { return route_test_candidates_.size(); }

  void SetRouteSelectionSource(int source) { source_ = source; }

  std::vector<RouteCandidate>& route_test_candidates() {
    return route_test_candidates_;
  }

  void SetServiceName(const std::string& service_name) {
    service_name_ = service_name;
  }

  std::string GetServiceName() const { return service_name_; }

#if defined(OS_ANDROID) && BUILDFLAG(ENABLE_WEBSOCKETS)
  // |UpdateBestHostInOtherProcess| is only executed in main process, best host
  // in other process need to be updated by IPC channel from main process.
  void UpdateBestHostInOtherProcess(const std::string& best_host);
#endif

 protected:
  bool MoveToNextCandidate();

  bool DecideTestSchemeAndResetCandidateIndex();

  // Return true if current route selection test is completed right now.
  bool TryOneRouteSelectionTest();

  void OnGroupSelectionPartialResult(const std::string& best_host);
  void OnGroupSelectionCompleted(const std::string& best_host, int rv);

  virtual void StartRouteTest() = 0;

  virtual void OnOneRouteTestCompleted(const RouteCandidate& route_info,
                                       int duration,
                                       int rv,
                                       bool from_cache) = 0;

  size_t test_index_;

  bool dsa_edge_route() const { return dsa_edge_route_; }

  bool ttfb_enabled() const { return ttfb_enabled_; }

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class URLDispatcherRouteSelectionTest;
#endif
  void OnRouteTestRequestComplete(const RouteCandidate& target_candidate,
                                  base::TimeTicks start_timeticks,
                                  int response_code,
                                  const std::string& content,
                                  HttpResponseHeaders* responseHeaders);

  const GURL BuildRequestURL(const std::string& target_scheme_host);

  const std::string ConvertSchemeOptionToString(SchemeOption option) const;

  static SchemeOption ConvertSchemeStringToOptionEnum(
      const std::string& scheme);

  void SendFeedbackLog(const std::string& best_host, int rv);

  void SaveBestTargetToFile(const std::string& best_target,
                            const bool is_success);

  void GetBestTargetFromCacheFile();

  int scheme_option_;

  RouteTestResultTable* route_test_result_;

  std::vector<RouteCandidate> route_test_candidates_;

  std::string test_scheme_;

  url::SchemeHostPort best_target_;
  int best_target_failures_;

  // The number of times for selecting best host.
  int select_times_;

  CompletionOnceCallback completion_callback_;
  bool is_test_in_progress_;

  bool can_use_global_route_test_result_;

  std::string sign_;

  int64_t epoch_;

  unsigned int priority_{0};

  std::string service_name_;

  std::string concurrent_call_best_host_;

  // Route selection triggered by
  // |RouteSelectionManager.route_selection_source_|.
  int source_{-1};

  // Record the latest start time of route selection.
  int64_t latest_route_select_start_time_{0};

  bool dsa_edge_route_{false};

  bool ttfb_enabled_{false};

  base::WeakPtrFactory<RouteSelectionGroup> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(RouteSelectionGroup);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_ROUTE_SELECTION_GROUP_H_
