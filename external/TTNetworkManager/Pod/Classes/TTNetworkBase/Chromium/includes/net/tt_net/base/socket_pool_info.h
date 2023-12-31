// Copyright (c) 2018 The ByteDacnce Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_SOCKET_POOL_INFO_H_
#define NET_TT_NET_BASE_SOCKET_POOL_INFO_H_

#include <stdint.h>
#include <vector>

#include "base/time/time.h"
#include "net/base/net_export.h"
#include "net/net_buildflags.h"

namespace net {

enum PendingReason {
  NOT_PENDING = 0,
  STALLED_MAX_SOCKETS_PER_GROUP,
  STALLED_MAX_SOCKETS,
  ASSIGNED_JOB_BUT_REUSED
};

enum ReuseType {
  UNUSED = 0,   // unused socket that just finished connecting
  UNUSED_IDLE,  // unused socket that has been idle for awhile
  REUSED_IDLE   // previously used socket
};

enum AssignType {
  NOT_ASSIGNED = 0,
  IDLE_SOCKET,
  EXTRA_CONNECT_JOB,
  NEW_CONNECT_JOB
};

#if BUILDFLAG(TTNET_IMPLEMENT_ENABLE_SOCKET_DETAIL_MONITOR)
enum SocketPoolState {
  IS_POOL_STALLED = 1 << 0,
  IS_GROUP_STALLED = 1 << 1,
  IS_BACKGROUND_JOB_RUN = 1 << 2,
};
#endif

// Structure containing socket pool information for a request.
//
// It gives the experience of the request in the socket pool phases.
//
struct NET_EXPORT SocketPoolInfo {
  SocketPoolInfo();
  SocketPoolInfo(const SocketPoolInfo& other);
  ~SocketPoolInfo();

  PendingReason pending_reason;

  ReuseType socket_reuse_type;

  AssignType socket_assign_type;

  bool is_backup_job;

  base::TimeDelta socket_idle_time;

  base::TimeTicks enter_pool;
  base::TimeTicks start_handling;
  base::TimeTicks leave_pool;
#if BUILDFLAG(TTNET_IMPLEMENT_ENABLE_SOCKET_DETAIL_MONITOR)
  // socket pool info
  uint8_t pool_state_flag;  // SocketPoolState
  uint16_t connecting_socket_count;
  uint16_t handed_out_socket_count;
  uint16_t idle_socket_count;
  // using socket pool group info
  std::string group_key;
  uint16_t group_active_socket_count;
  uint16_t group_idle_socket_count;
  uint16_t group_connect_job_count;
  uint16_t group_pending_request_count;
#endif
};

}  // namespace net

#endif  // NET_TT_NET_BASE_SOCKET_POOL_INFO_H_
