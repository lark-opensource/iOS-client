// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXPERIENCE_MANAGER_REQUEST_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXPERIENCE_MANAGER_REQUEST_H_

#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"

namespace net {
namespace tt_exp {

// Request is owned by caller of Network Detect module, and it's used
// for caller to interact with net detect job.
class TTNET_IMPLEMENT_EXPORT TTNetExperienceManager::Request {
 public:
  Request(std::unique_ptr<RequestConfig> config,
          TTNetExperienceManager* manager);

  virtual ~Request();

  int Start(CompletionOnceCallback callback);

  void Cancel();

  void DoExtraCommand(const std::string& command,
                      const std::string& extra_message);

  const std::string& GetReport() const { return job_report_; }

  bool IsCompleted() const { return complete_; }

 private:
  friend class TTNetExperienceManager::Job;
  friend class TTNetExperienceManager;
  friend class TTNetExpDiagnosisPinger;

  void OnJobComplete(Job* job, int error);

  RequestConfig* config() const { return config_.get(); }

  void BindJob(Job* job);

  void CollectJobReport(const std::string& report) { job_report_ = report; }

  // The net detect job that this Request depends on.
  Job* job_;

  // The user's callback to invoke when the request completes.
  CompletionOnceCallback callback_;

  std::unique_ptr<RequestConfig> config_;

  TTNetExperienceManager* manager_;

  // Whether the request has completed.
  bool complete_;

  std::string job_report_;

  DISALLOW_COPY_AND_ASSIGN(Request);
};

}  // namespace tt_exp
}  // namespace net

#endif