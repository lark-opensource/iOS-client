// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TT_NETWORK_DETECT_DISPATCHED_MANAGER_JOB_H_
#define NET_TT_NET_NET_DETECT_TT_NETWORK_DETECT_DISPATCHED_MANAGER_JOB_H_

#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"

namespace net {
// Job does the real detection by the transations held by it.
class TTNetworkDetectDispatchedManager::Job
    : public PrioritizedDispatcher::Job,
      public tt_detect::TTNetDetectTransactionCallback {
 public:
  Job(TTNetworkDetectDispatchedManager* manager,
      TTNetworkDetectDispatchedManager::Request* request);

  ~Job() override;

  // Initialize variable configuration
  void Init();

  // PrioritizedDispatcher::Job implementation:
  // Must complete asynchronously.
  void Start() override;

  // Cancel and destruct job without notifying callback..
  void Cancel(int result);

  // Add this Job to dispatcher.
  void Schedule(bool at_head);

  // After when the job is created and added to job set, this method should be
  // called.
  void OnAddToJobList(
      TTNetworkDetectDispatchedManager::JobList::iterator self_iterator);

  // After when the job is removed from the job set, this method should be
  // called.
  void OnRemovedFromJobList();

  // If the jobs in |job_dispatcher_| reach the limit of
  // |max_queued_jobs_count_|, the oldest and priority-lowest job should be
  // evicted from |job_dispatcher_|, and call this method of evicted job.
  // Further more, if the evicted job is the job newly added to
  // |job_dispatcher_|, set |complete_asynchronously| false.
  void OnEvictedFromQueue(bool complete_asynchronously);

  bool is_running() const { return is_running_; }

  bool is_queued() const { return !dispatcher_handle_.is_null(); }

  bool skip_dispatch() const { return skip_dispatch_; }

  // Abort job when network changes and notify callback.
  void Abort();

 private:
  friend class TTNetworkDetectDispatchedManager::MockJob;

  // Collect report of all transactions when the Job is done.
  void CollectTransactionsReport();

  // While report key progress of transaction, call this to notify progress.
  void DoDetectProgress(int result);

  // While timeout or all transactions finish detection,
  // call this to finish this job.
  void DoDetectComplete(int result);

  // Detection timeout handler.
  void OnTimeout();

  // TTNetDetectTransactionCallback implementation:
  void OnDetectTransactionProgress() override;

  // TTNetDetectTransactionCallback implementation:
  void OnDetectTransactionFinish() override;

  TTNetworkDetectDispatchedManager* manager_;

  // Owned by caller of Network Detect module.
  TTNetworkDetectDispatchedManager::Request* request_;

  // Based on detect type
  std::vector<scoped_refptr<tt_detect::TTNetDetectTransaction>>
      transaction_list_;

  // Count of transactions that have finished net detection.
  uint32_t finished_transactions_count_;

  base::OneShotTimer timeout_timer_;

  bool is_running_;

  // If true, the job will skip the dispatcher and start directly.
  bool skip_dispatch_;

  // After added to |job_dispatcher_|, we will get a |dispatcher_handle_|.
  // By using this, we can modify the job's priority in |job_dispatcher_|,
  // or remove the job from the |job_dispatcher_|.
  PrioritizedDispatcher::Handle dispatcher_handle_;

  // Iterator to |this| in the JobList. |nullopt| if not owned by the JobList.
  base::Optional<TTNetworkDetectDispatchedManager::JobList::iterator>
      self_iterator_;

  base::WeakPtrFactory<TTNetworkDetectDispatchedManager::Job> factory_;
};
}  // namespace net

#endif