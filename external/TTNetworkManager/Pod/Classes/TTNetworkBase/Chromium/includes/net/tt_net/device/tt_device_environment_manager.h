// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_DEVICE_TT_DEVICE_ENVIRONMENT_MANAGER_H_
#define NET_TT_NET_DEVICE_TT_DEVICE_ENVIRONMENT_MANAGER_H_

#include "base/memory/singleton.h"

namespace net {

class TTDeviceEnvironmentManager {
 public:
  static TTDeviceEnvironmentManager* GetInstance();

  virtual bool Init();

  const std::string& GetGatewayIP() const { return gateway_ip_; }
  const std::string GetNameServersInfo() const { return nameservers_info_; }

 protected:
  TTDeviceEnvironmentManager();
  virtual ~TTDeviceEnvironmentManager();
  virtual void ObtainGatewayIP();
  virtual void ObtainNameServersInfo();

  bool initialized_{false};
  std::string gateway_ip_;
  std::string nameservers_info_;

 private:
  friend struct base::DefaultSingletonTraits<TTDeviceEnvironmentManager>;

  DISALLOW_COPY_AND_ASSIGN(TTDeviceEnvironmentManager);
};

}  // namespace net

#endif  // NET_TT_NET_DEVICE_TT_DEVICE_ENVIRONMENT_MANAGER_H_
