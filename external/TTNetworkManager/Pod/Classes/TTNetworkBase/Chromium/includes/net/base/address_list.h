// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_BASE_ADDRESS_LIST_H_
#define NET_BASE_ADDRESS_LIST_H_

#include <stdint.h>

#include <string>
#include <vector>

#include "base/compiler_specific.h"
#include "base/ttnet_implement_buildflags.h"
#include "net/base/ip_endpoint.h"
#include "net/base/net_export.h"

struct addrinfo;

namespace base {
class Value;
}

namespace net {

class IPAddress;

class TTNET_IMPLEMENT_EXPORT NET_EXPORT AddressList {
 public:
#if BUILDFLAG(TTNET_IMPLEMENT)
  // Indicates the source where the address list get from.
  enum Source {
    NOT_SET = 0,
    // For chromium host resolver implementation:
    SERVE_FROM_IP = 1,
    SERVE_FROM_CACHE = 2,
    SERVE_FROM_HOSTS = 3,
    SERVE_FROM_LOCALHOST = 4,
    SERVE_FROM_PREFER_ADDR = 5,
    SERVE_FROM_HTTP_DNS_JOB = 6,
    SERVE_FROM_ASYNC_DNS_JOB = 7,
    SERVE_FROM_PROC_DNS_JOB = 8,
    SERVE_FROM_HARDCODED_HOSTS = 9,
    SERVE_FROM_STALE_HOST_CACHE = 10,
    // For ttnet wise host resolver implementation:
    SERVE_FROM_DIRECT_RESOLVE = 11,
    SERVE_FROM_LOCAL_DNS_CACHE = 12,
    SERVE_FROM_LOCAL_DNS_QUERY = 13,
    SERVE_FROM_CUSTOMIZED_DNS_CACHE = 14,
    SERVE_FROM_CUSTOMIZED_DNS_QUERY = 15,
    SERVE_FROM_HTTP_DNS_CACHE = 16,
    SERVE_FROM_HTTP_DNS_QUERY = 17,
    SERVE_FROM_FINAL_BACKUP_CACHE = 18,
    SERVE_FROM_PRELOAD_BATCH_HTTP_DNS_JOB = 19,
    SERVE_FROM_ASYNC_BATCH_HTTP_DNS_JOB = 20,
    SERVE_FROM_BACKUP_STALE_CACHE = 21,
    SERVE_FROM_RACE_STALE_CACHE = 22
  };

  bool is_auth() const { return is_auth_; }
  void set_auth(bool auth) { is_auth_ = auth; }
  Source source() const { return source_; }
  void set_source(Source source) { source_ = source; }
  int cache_source() const { return cache_source_; }
  void set_cache_source(int cache_source) { cache_source_ = cache_source; }
  const IPAddress& queried_with_ip() const { return queried_with_cip_; }
  void set_queried_with_ip(const IPAddress& query_ip) {
    queried_with_cip_ = query_ip;
  }
  bool from_stale_cache() const { return from_stale_cache_; }
  void set_from_stale_cache(bool stale) const { from_stale_cache_ = stale; }
  int net_type() const { return net_type_; }
  void set_net_type(int net_type) const { net_type_ = net_type; }
  int action() const { return action_; }
  void set_action(int action) const { action_ = action; }
#endif
  AddressList();
  AddressList(const AddressList&);
  AddressList& operator=(const AddressList&);
  ~AddressList();

  // Creates an address list for a single IP literal.
  explicit AddressList(const IPEndPoint& endpoint);

  static AddressList CreateFromIPAddress(const IPAddress& address,
                                         uint16_t port);

  static AddressList CreateFromIPAddressList(const IPAddressList& addresses,
                                             const std::string& canonical_name);

  // Copies the data from |head| and the chained list into an AddressList.
  static AddressList CreateFromAddrinfo(const struct addrinfo* head);

  // Returns a copy of |list| with port on each element set to |port|.
  static AddressList CopyWithPort(const AddressList& list, uint16_t port);

  // TODO(szym): Remove all three. http://crbug.com/126134
  const std::string& canonical_name() const { return canonical_name_; }

  void set_canonical_name(const std::string& canonical_name) {
    canonical_name_ = canonical_name;
  }

  // Sets canonical name to the literal of the first IP address on the list.
  void SetDefaultCanonicalName();

  // Creates a value representation of the address list, appropriate for
  // inclusion in a NetLog.
  base::Value NetLogParams() const;

  // Deduplicates the stored addresses while otherwise preserving their order.
  void Deduplicate();

  using iterator = std::vector<IPEndPoint>::iterator;
  using const_iterator = std::vector<IPEndPoint>::const_iterator;

  size_t size() const { return endpoints_.size(); }
  bool empty() const { return endpoints_.empty(); }
  void clear() { endpoints_.clear(); }
  void reserve(size_t count) { endpoints_.reserve(count); }
  size_t capacity() const { return endpoints_.capacity(); }
  IPEndPoint& operator[](size_t index) { return endpoints_[index]; }
  const IPEndPoint& operator[](size_t index) const { return endpoints_[index]; }
  IPEndPoint& front() { return endpoints_.front(); }
  const IPEndPoint& front() const { return endpoints_.front(); }
  IPEndPoint& back() { return endpoints_.back(); }
  const IPEndPoint& back() const { return endpoints_.back(); }
  void push_back(const IPEndPoint& val) { endpoints_.push_back(val); }

  template <typename InputIt>
  void insert(iterator pos, InputIt first, InputIt last) {
    endpoints_.insert(pos, first, last);
  }
  iterator begin() { return endpoints_.begin(); }
  const_iterator begin() const { return endpoints_.begin(); }
  iterator end() { return endpoints_.end(); }
  const_iterator end() const { return endpoints_.end(); }

  const std::vector<net::IPEndPoint>& endpoints() const { return endpoints_; }
  std::vector<net::IPEndPoint>& endpoints() { return endpoints_; }

 private:
  std::vector<IPEndPoint> endpoints_;
  // TODO(szym): Remove. http://crbug.com/126134
  std::string canonical_name_;

#if BUILDFLAG(TTNET_IMPLEMENT)
  bool is_auth_{false};
  // Indicates where the request is finally resolved from.
  Source source_{NOT_SET};
  int cache_source_{-1};
  // Indicates the nameserver saw client query ip.
  IPAddress queried_with_cip_;
  mutable bool from_stale_cache_{false};
  mutable int net_type_{0};
  mutable int action_{-1};
#endif
};

}  // namespace net

#endif  // NET_BASE_ADDRESS_LIST_H_
