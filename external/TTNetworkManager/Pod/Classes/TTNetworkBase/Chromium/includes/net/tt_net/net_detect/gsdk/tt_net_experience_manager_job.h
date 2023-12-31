// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXPERIENCE_MANAGER_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXPERIENCE_MANAGER_JOB_H_

#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"

#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"

namespace net {
namespace tt_exp {
// Job does the real detection by the transations held by it.
class TTNetExperienceManager::Job : public PrioritizedDispatcher::Job {
 public:
  Job(const TNCConfig& tnc_config,
      TTNetExperienceManager::Request* request);

  ~Job() override;

  // PrioritizedDispatcher::Job implementation:
  void Start() override;

  // Calling Cancel will destruct job.
  void Cancel();

  virtual void DoExtraCommand(const std::string& command,
                              const std::string& extra_message);

  // Finish Job.
  void Finish();

  // Add this Job to dispatcher.
  void Schedule(bool at_head, bool skip_dispatch);

  // Detection timeout handler.
  void OnTimeout();

  // After when the job is created and added to job set, this method should be
  // called.
  void OnAddToJobList(TTNetExperienceManager::JobList::iterator self_iterator);

  // After when the job is removed from the job set, this method should be
  // called.
  void OnRemovedFromJobList();

  // If the jobs in |job_dispatcher_| reach the limit of
  // |max_queued_jobs_count_|, the oldest and priority-lowest job should be
  // evicted from |job_dispatcher_|, and call this method of evicted job.
  // Further more, if the evicted job is the job newly added to
  // |job_dispatcher_|, set |complete_asynchronously| false.
  void OnEvictedFromQueue(bool complete_asynchronously);

  // std::unique_ptr<base::ListValue> GetDetailReport() {}

  // std::unique_ptr<base::ListValue> GetSimpleReport() {}

  bool is_running() const { return is_running_; }

  bool is_queued() const { return !dispatcher_handle_.is_null(); }

 protected:
  // While timeout or all transactions finish detection,
  // call this to finish this job. It will cause |this| job be deleted. Don't do
  // anything after this invocation.
  void OnJobComplete(int result);

  virtual int StartInternal() = 0;

  virtual void CollectReport(int result) = 0;

  virtual int ParseCustomTNCConfig();

  std::unique_ptr<TTNetworkDetectDispatchedManager::Request> detect_request_;

  // Owned by caller of Network Detect module.
  TTNetExperienceManager::Request* request_;

  bool is_running_;

  int result_{ND_ERR_OK};

  // After added to |job_dispatcher_|, we will get a |dispatcher_handle_|.
  // By using this, we can modify the job's priority in |job_dispatcher_|,
  // or remove the job from the |job_dispatcher_|.
  PrioritizedDispatcher::Handle dispatcher_handle_;

  TTNetExperienceManager* manager_;

  // Extra info when job starts. Probably it's a player ID of external game
  // studio.
  std::string extra_info_;

  TNCConfig tnc_config_;

 private:
  // It will cause |this| job be deleted. Don't do
  // anything after this invocation.
  void OnJobCompleteWithError(int error);

  // If true, the job will skip the dispatcher and start directly.
  bool skip_dispatch_;

  // If this job has been canceled, it will not be canceled again.
  bool canceled_;

  // Iterator to |this| in the JobList. |nullopt| if not owned by the JobList.
  base::Optional<TTNetExperienceManager::JobList::iterator> self_iterator_;

  base::OneShotTimer timeout_timer_;

  base::WeakPtrFactory<TTNetExperienceManager::Job> factory_;
};

}  // namespace tt_exp
}  // namespace net

#endif