// Copyright 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_ADDRESS_LIST_RESORTER_H_
#define NET_TT_NET_BASE_ADDRESS_LIST_RESORTER_H_

#include <memory>

#include "base/memory/singleton.h"
#include "net/base/address_list.h"

namespace net {

enum AddressListResorterType {
  ADDRESS_LIST_RESORTER_NONE = 0,
  ADDRESS_LIST_RESORTER_SIMPLE,
  ADDRESS_LIST_RESORTER_LAST = ADDRESS_LIST_RESORTER_SIMPLE
};

class AddressListResorter {
 public:
  struct AddressMetrics {
    AddressMetrics(int error);
    AddressMetrics(const AddressMetrics& other);
    ~AddressMetrics();

    int net_error;
  };

  static AddressListResorter* GetInstance();
  virtual ~AddressListResorter();

  virtual void Resort(AddressList& address_list);

  virtual void UpdateAddressMetrics(const IPEndPoint& address,
                                    const AddressMetrics& metrics);

 protected:
  AddressListResorter(AddressListResorter* impl);

 private:
  friend struct base::DefaultSingletonTraits<AddressListResorter>;

  AddressListResorter();

  std::unique_ptr<AddressListResorter> impl_;

  DISALLOW_COPY_AND_ASSIGN(AddressListResorter);
};

}  // namespace net

#endif  // NET_TT_NET_BASE_ADDRESS_LIST_RESORTER_H_
