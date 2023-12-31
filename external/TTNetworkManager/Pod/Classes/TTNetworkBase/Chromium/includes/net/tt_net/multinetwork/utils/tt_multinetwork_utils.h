// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_UTILS_H_
#define NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_UTILS_H_

#include <netdb.h>

#include "base/observer_list.h"
#include "net/base/address_family.h"
#include "net/base/network_change_notifier.h"
#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/dns/host_resolver.h"
#endif

namespace net {

// This class is used by TTMultiNetworkManager for doing low-level
// platform-related works:
// 1. Resolve host via Cellular interface.
// 2. Bind specified socket to Cellular interface.
// 3. Keep network interfaces information.
// The only object should only be held by TTMultiNetworkManager.
class TTMultiNetworkUtils {
 public:
  using ActivatingCellCallback = base::OnceCallback<void(bool)>;

  // Control a specified host resolving request or socket connecting to follow
  // TTMultiNetworkManager's state or always use WiFi/Cellular.
  enum MultiNetAction {
    // Default value.
    ACTION_NOT_SPECIFIC = 0,
    // Always try to use Cellular even if its net id is unavailable.
    ACTION_FORCE_CELLULAR = 1,
    // Always try to use WiFi even if its net id is unavailable.
    ACTION_FORCE_WIFI = 2,
    // Always use system determined default network, not bind to WiFi or
    // Cellular's net id.
    ACTION_FORCE_DEFAULT_NETWORK = 3,
    ACTION_COUNT
  };

  enum UnsupportedReason {
    REASON_INVALID = -1,
    REASON_OS_VERSION = 0,
    REASON_DLOPEN_FAIL,
    REASON_DLSYM_FAIL_BINDNETWORK,
    REASON_DLSYM_FAIL_HOST_RESOLV,
    REASON_UNKNOWN_CONNECTING_NET_TYPE,
    REASON_UNKNOWN_DISCONNECTING_NET_TYPE,
    REASON_NO_IP_BOUND_IF,
    REASON_COUNT
  };

  class MultiNetChangeObserver {
   public:
    MultiNetChangeObserver() {}
    virtual ~MultiNetChangeObserver() {}
    virtual void OnMultiNetChanged() = 0;
  };

  static TTMultiNetworkUtils* GetInstance();

  // For local DNS resolving.
  // Returning true means Local DNS via specified network(WiFi/Cellular) is
  // successful, while false means resolving failed.
  // The meaning of different values of |net_error| is as following:
  // 1. OK, means that |action| tells that don't resolve by specifying WiFi
  //    nor Cellular network. In other words, use system DEFAULT network.
  // 2. ERR_NOT_IMPLEMENTED, means current OS version doesn't support
  //    multinetwork, or multinetwork environment hasn't been prepared.
  // 3. Other values, means specified network is unavailable, or the OS's API
  //    is invoked correctly for resolving but failed.
  int GetAddrInfo(const char* node,
                  const char* service,
                  const struct addrinfo* hints,
                  struct addrinfo** res,
                  bool* sys_api_resolved,
                  HostResolverFlags flags) const;

  // We have our own implementation of |res| memory allocation for
  // GetAddrInfoViaCellular, thus we need to release it by ourself if it
  // was not allocated by system API of getaddrinfo.
  void FreeAddrInfo(struct addrinfo* res, bool sys_api_resolved);

  // For socket binding network.
  // Returning true means binding |socket_fd| to specified
  // network(WiFi/Cellular) successfully, while false means binding failed. The
  // meaning of different values of |net_error| is as following:
  // 1. OK, means that |action| tells that don't bind to WiFi nor Cellular. In
  //    other words, use system DEFAULT network.
  // 2. ERR_NOT_IMPLEMENTED, means current OS version doesn't support
  //    multinetwork, or multinetwork environment hasn't been prepared.
  // 3. Other values, means specified network is unavailable, or the OS's API
  //    is invoked correctly for binding but failed.
  bool TryBindToMultiNetwork(int socket_fd,
                             int* net_error,
                             MultiNetAction action) const;

  virtual bool PrepareEnvironment();

  // If network list changes, return true. Return false otherwise.
  virtual bool TryUpdateNetworkList();

  // For some Android mobiles(like Huawei), when WiFi is connected, Cellular
  // becomes unavailable by default. If we want to use Cellular simultaneously,
  // we should call Android API first to make Cellular up. For iOS, when WiFi
  // is connected, Cellular is available by default.
  // If callback is runned and result is true, Cellular net id must have been
  // available.
  virtual bool TryAlwaysUpCellular(ActivatingCellCallback callback);

  virtual void OnCellularAlwaysUp(bool success);

  virtual bool IsWiFiAvailable() const = 0;

  virtual bool IsCellularAvailable() const = 0;

  virtual bool IsVpnOn() const = 0;

  virtual NetworkChangeNotifier::ConnectionType GetConnectionTypeOfCellular()
      const = 0;

  bool IsEnvironmentSupported() const { return !environment_unsupported_; }

  int GetUnsupportedReason() const {
    return static_cast<int>(unsupported_reason_);
  }

  void ResetUnsupportedReason();

  void AddMultiNetChangeObserver(MultiNetChangeObserver* observer);

  void RemoveMultiNetChangeObserver(MultiNetChangeObserver* observer);

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
  void GetMultiNetResolveHostParameters(
      MultiNetAction action,
      HostResolver::ResolveHostParameters& parameters_out);
#else
  void GetMultiNetResolveHostParameters(MultiNetAction action,
                                               HostResolverFlags& flags_out);
#endif

  NetworkChangeNotifier::ConnectionType GetConnectionType(
      MultiNetAction action);

 protected:
  TTMultiNetworkUtils();

  virtual ~TTMultiNetworkUtils();

  virtual bool GetAddrInfoInternal(const char* node,
                                   const char* service,
                                   const struct addrinfo* hints,
                                   struct addrinfo** res,
                                   int* net_error,
                                   int* os_error,
                                   HostResolverFlags flags) const = 0;

  virtual void FreeAddrInfoInternal(struct addrinfo* res) = 0;

  virtual bool TryBindToMultiNetworkInternal(int socket_fd,
                                             int* net_error,
                                             MultiNetAction action) const = 0;

  void NotifyObserversOfMultiNetChanged();

  void RunCallbackOfActivatingCellResultIfNeeded(bool success);

  // If true, means that current OS doesn't support multinetwork, such as
  // OS version is too low.
  bool environment_unsupported_;

  UnsupportedReason unsupported_reason_;

  bool environment_prepared_;

  std::vector<ActivatingCellCallback> activating_cell_callbacks_;

  NetworkChangeNotifier::ConnectionType default_connection_type_{
      NetworkChangeNotifier::CONNECTION_UNKNOWN};

 private:
  bool GetAddrInfoBySpecifiedNetwork(const char* node,
                                     const char* service,
                                     const struct addrinfo* hints,
                                     struct addrinfo** res,
                                     int* net_error,
                                     int* os_error,
                                     HostResolverFlags flags) const;

  // When |TTMultiNetworkUtils| is notified of network change, notify
  // |multi_net_change_observer_list_| further.
  base::ObserverList<MultiNetChangeObserver>::Unchecked
      multi_net_change_observer_list_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void ResetForTesting();
#endif
};

}  // namespace net

#endif