// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TT_NETWORK_DETECT_DISPATCHED_MANAGER_REQUEST_H_
#define NET_TT_NET_NET_DETECT_TT_NETWORK_DETECT_DISPATCHED_MANAGER_REQUEST_H_

#include "net/base/completion_repeating_callback.h"
#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"
#include "transactions/tt_net_detect_transaction.h"

namespace net {
// Request is owned by caller of Network Detect module, and it's used
// for caller to interact with net detect job.
class TTNetworkDetectDispatchedManager::Request {
 public:
  Request(std::unique_ptr<RequestConfig> config,
          TTNetworkDetectDispatchedManager* manager);

  // Use virtual for testing.
  virtual ~Request();

  virtual void Cancel(int error);

  virtual int Start(CompletionOnceCallback completion_callback);

  virtual int Start(CompletionOnceCallback completion_callback,
                    CompletionRepeatingCallback progress_callback);

  virtual void CollectDetectReports(
      std::vector<std::unique_ptr<tt_detect::BaseDetectReport>>& reports);

  virtual std::vector<std::unique_ptr<tt_detect::BaseDetectReport>>&
  GetDetectReports();

  virtual bool IsFinished() const;

  base::WeakPtr<TTNetworkDetectDispatchedManager::Request> GetWeakPtr() {
    return weak_factory_.GetWeakPtr();
  }

 private:
  friend class TTNetworkDetectDispatchedManager::Job;
  friend class TTNetworkDetectDispatchedManager::MockRequest;
  friend class TTNetworkDetectDispatchedManager::MockJob;

  void OnJobProgress(Job* job, int result);

  void OnJobComplete(Job* job, int result);

  std::vector<tt_detect::DetectTarget> targets() const { return targets_; }

  RequestConfig* config() const { return config_.get(); }

  void BindJob(Job* job);

  // The net detect job that this Request depends on.
  Job* job_;

  // The user's callback to invoke when the request progresses.
  CompletionRepeatingCallback progress_callback_;

  // The user's callback to invoke when the request completes.
  CompletionOnceCallback completion_callback_;

  std::vector<tt_detect::DetectTarget> targets_;

  std::unique_ptr<RequestConfig> config_;

  TTNetworkDetectDispatchedManager* manager_;

  // Whether the request has finished.
  bool is_finished_;

  std::vector<std::unique_ptr<tt_detect::BaseDetectReport>> detect_reports_;

  base::WeakPtrFactory<TTNetworkDetectDispatchedManager::Request> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Request);
};

}  // namespace net

#endif