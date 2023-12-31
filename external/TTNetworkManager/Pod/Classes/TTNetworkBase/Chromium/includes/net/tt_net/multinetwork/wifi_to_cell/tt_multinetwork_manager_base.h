// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_WIFI_TO_CELL_TT_MULTINETWORK_MANAGER_BASE_H_
#define NET_TT_NET_MULTINETWORK_WIFI_TO_CELL_TT_MULTINETWORK_MANAGER_BASE_H_

#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"

namespace net {

class TTMultiNetworkManagerBase
    : public TTMultiNetworkUtils::MultiNetChangeObserver {
 public:
  enum State {
    STATE_STOPPED = -1,
    STATE_NO_NETWORK = 0,
    STATE_DEFAULT_CELLULAR_WITH_WIFI_DOWN = 1,
    STATE_DEFAULT_WIFI_WITH_CELLULAR_DOWN = 2,
    STATE_DEFAULT_WIFI_WITH_CELLULAR_UP = 3,
    STATE_WAIT_CELLULAR_ALWAYS_UP = 4,
    STATE_WAIT_USER_ENABLE = 5,
    STATE_WIFI_WITH_CELLULAR_TRANS_DATA = 6,
    STATE_EVALUATE_CELLULAR = 7,
    STATE_COUNT
  };

 protected:
  enum Event {
    EVENT_ON_ECT_CHANGED = 0,
    EVENT_ON_NETWORK_CHANGED = 1,
    EVENT_ON_USER_ENABLE_SWITCH = 2,
    EVENT_ON_CELLULAR_ALWAYS_UP = 3,
    EVENT_ON_WAIT_USER_ENABLE_TIMEOUT = 4,
    EVENT_ON_WAIT_CELLULAR_ALWAYS_UP_TIMEOUT = 5,
    EVENT_ON_DETECT_LONG_TERM_POOR_NETWORK = 6,
    EVENT_ON_DETECT_WIFI_RECOVER = 7,
    EVENT_ON_SERVER_CONFIG_CHANGED = 8,
    EVENT_ON_PENDING_REQUEST_NOT_EMPTY = 9,
    EVENT_ON_STATE_SYNC = 10,  // For subprocess, not main process.
    EVENT_ON_EVALUATE_CELLULAR_DONE = 11,
    EVENT_ON_TRIGGER_START = 12,
    EVENT_ON_TRIGGER_STOP = 13,
    EVENT_ON_ACTIVATE_CELLULAR = 14,
    EVENT_ON_RECV_WIFI_TO_CELL_REQ = 15,
    EVENT_COUNT,
  };

  virtual void DoLoop(Event ev) = 0;

  // States' behaviour, called by DoLoop().
  virtual void DoStopped(Event ev) {}
  virtual void DoNoNetwork(Event ev) {}
  virtual void DoDefaultCellularWithWiFiDown(Event ev) {}
  virtual void DoDefaultWiFiWithCellularDown(Event ev) {}
  virtual void DoDefaultWiFiWithCellularUp(Event ev) {}
  virtual void DoWaitUserEnable(Event ev) {}
  virtual void DoWaitCellularAlwaysUp(Event ev) {}
  virtual void DoWiFiWithCellularTransData(Event ev) {}
  virtual void DoEvaluateCellular(Event ev) {}
};

}  // namespace net

#endif