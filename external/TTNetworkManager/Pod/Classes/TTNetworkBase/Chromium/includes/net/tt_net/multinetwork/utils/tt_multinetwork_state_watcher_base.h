// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_STATE_WATCHER_BASE_H_
#define NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_STATE_WATCHER_BASE_H_

namespace net {

class NET_EXPORT_PRIVATE TTMultiNetworkStateWatcherBase {
 public:
  enum State {
    STATE_STOPPED = -1,
    STATE_NO_NETWORK = 0,
    STATE_DEFAULT_CELLULAR_WITH_WIFI_DOWN = 1,
    STATE_DEFAULT_WIFI_WITH_CELLULAR_DOWN = 2,
    STATE_DEFAULT_WIFI_WITH_CELLULAR_UP = 3,
    STATE_WAIT_CELLULAR_ALWAYS_UP = 4,
    STATE_DEFAULT_VPN = 5,
    STATE_COUNT
  };

  class MultiNetStateObserver {
   public:
    virtual void OnMultiNetStateChanged(State prev_state, State curr_state) = 0;

    virtual void OnUserSpecifyingNetworkEnabled(bool enable) {}

   protected:
    virtual ~MultiNetStateObserver() {}
  };

  virtual ~TTMultiNetworkStateWatcherBase() {}

  virtual void AddMultiNetStateObserver(MultiNetStateObserver* observer) = 0;

  virtual void RemoveMultiNetStateObserver(MultiNetStateObserver* observer) = 0;

  virtual void StartWatcher() = 0;

  virtual bool TryActivatingCellular() = 0;

  virtual int GetUnsupportedReason() const = 0;

  virtual void ResetUnsupportedReason() {}

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  virtual void StopWatcherForTesting() = 0;
#endif
};
}  // namespace net

#endif