// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_URL_REQUEST_TT_URL_REQUEST_MANAGER_H_
#define NET_TT_NET_URL_REQUEST_TT_URL_REQUEST_MANAGER_H_

#include "base/memory/singleton.h"
#include "base/observer_list.h"
#include "net/url_request/url_request.h"

namespace net {
class TTURLRequestManager {
 public:
  class PendingRequestObserver {
   public:
    enum CountChange {
      CHANGE_NOT_EMPTY = 0,
      CHANGE_CLEAN_UP = 1,
    };

    virtual void OnPendingRequestCountChanged(CountChange change) = 0;

   protected:
    PendingRequestObserver() {}
    virtual ~PendingRequestObserver() {}
  };

  static TTURLRequestManager* GetInstance();

  void AddObserver(PendingRequestObserver* observer);

  void RemoveObserver(PendingRequestObserver* observer);

  // Add a pending request for watching.
  void AddRequest(URLRequest* request);

  // Remove a pending request when it finishes.
  void RemoveRequest(URLRequest* request);

  bool HasPendingRequest() const;

  // Return the count of requests on going.
  uint64_t GetPendingRequestsCount() const { return pending_requests_.size(); }

  uint64_t total_requests() const { return total_requests_; }

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void set_has_pending_requests_for_testing(bool val) {
    has_pending_requests_for_testing_ = val;
  }

  void ClearPendingRequestsForTesting() { 
    pending_requests_.clear();
    total_requests_ = 0;
  }
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTURLRequestManager>;
  TTURLRequestManager();
  ~TTURLRequestManager();

  void NotifyObserversOfPendingRequestCountChange(
      PendingRequestObserver::CountChange change);

  base::ObserverList<PendingRequestObserver>::Unchecked observer_list_;

  // Pending request that is waiting for response.
  std::unordered_set<URLRequest*> pending_requests_;

  // Total requests since APP started.
  uint64_t total_requests_;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  bool has_pending_requests_for_testing_{false};
#endif
};
}  // namespace net

#endif