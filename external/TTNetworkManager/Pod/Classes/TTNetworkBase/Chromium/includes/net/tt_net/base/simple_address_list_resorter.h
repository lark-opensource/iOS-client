// Copyright 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_SOCKET_SIMPLE_ADDRESS_LIST_RESORTER_H_
#define NET_SOCKET_SIMPLE_ADDRESS_LIST_RESORTER_H_

#include "net/base/network_change_notifier.h"
#include "net/third_party/quiche/src/common/simple_linked_hash_map.h"
#include "net/tt_net/base/address_list_resorter.h"

namespace net {

class SimpleAddressListResorter
    : public AddressListResorter,
      public NetworkChangeNotifier::IPAddressObserver {
 public:
  SimpleAddressListResorter();
  ~SimpleAddressListResorter() override;

  void Resort(AddressList& address_list) override;

  void UpdateAddressMetrics(const IPEndPoint& address,
                            const AddressMetrics& metrics) override;

 private:
  struct IPEndPointHash {
    size_t operator()(const IPEndPoint& entry) const {
      return std::hash<std::string>()(entry.ToString());
    }
  };

  struct IPEndPointStatus {
    // Forbidden start time for the IPEndPoint.
    base::TimeTicks ip_forbidden_start;

    IPEndPointStatus();
    ~IPEndPointStatus();
  };

  // NetworkChangeNotifier::IPAddressObserver:
  void OnIPAddressChanged() override;

  // The bool is unused. Just to implement a linked hash set.
  quiche::SimpleLinkedHashMap<IPEndPoint, IPEndPointStatus, IPEndPointHash>
      ip_blacklist_;

  // Forbidden time duration for the IPEndPoint.
  int forbid_duration_;

  DISALLOW_COPY_AND_ASSIGN(SimpleAddressListResorter);
};

}  // namespace net

#endif  // NET_SOCKET_SIMPLE_ADDRESS_LIST_RESORTER_H_
