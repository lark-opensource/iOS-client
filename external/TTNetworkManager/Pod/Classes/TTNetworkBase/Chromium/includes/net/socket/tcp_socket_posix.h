// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_SOCKET_TCP_SOCKET_POSIX_H_
#define NET_SOCKET_TCP_SOCKET_POSIX_H_

#include <stdint.h>

#include <memory>

#include "base/callback.h"
#include "base/compiler_specific.h"
#include "base/macros.h"
#include "net/base/address_family.h"
#include "net/base/completion_once_callback.h"
#include "net/base/net_export.h"
#include "net/log/net_log_with_source.h"
#include "net/socket/socket_descriptor.h"
#include "net/socket/socket_performance_watcher.h"
#include "net/socket/socket_tag.h"
#include "net/traffic_annotation/network_traffic_annotation.h"

#if BUILDFLAG(TTNET_IMPLEMENT)
#include "net/net_buildflags.h"
#include "net/tt_net/base/socket_timeout_param.h"
#endif

namespace base {
class TimeDelta;
}

namespace net {

class AddressList;
class IOBuffer;
class IPEndPoint;
class SocketPosix;
class NetLog;
struct NetLogSource;
class SocketTag;
#if BUILDFLAG(TTNET_IMPLEMENT)
class SocketPosixWrapper;
#endif
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
class TTTCPInfoHelper;
#endif

class NET_EXPORT TCPSocketPosix {
 public:
  // |socket_performance_watcher| is notified of the performance metrics related
  // to this socket. |socket_performance_watcher| may be null.
  TCPSocketPosix(
      std::unique_ptr<SocketPerformanceWatcher> socket_performance_watcher,
      NetLog* net_log,
      const NetLogSource& source);
  virtual ~TCPSocketPosix();

  // Opens the socket.
  // Returns a net error code.
  int Open(AddressFamily family);

  // Takes ownership of |socket|, which is known to already be connected to the
  // given peer address. However, peer address may be the empty address, for
  // compatibility. The given peer address will be returned by GetPeerAddress.
  int AdoptConnectedSocket(SocketDescriptor socket,
                           const IPEndPoint& peer_address);
  // Takes ownership of |socket|, which may or may not be open, bound, or
  // listening. The caller must determine the state of the socket based on its
  // provenance and act accordingly. The socket may have connections waiting
  // to be accepted, but must not be actually connected.
  int AdoptUnconnectedSocket(SocketDescriptor socket);

  // Binds this socket to |address|. This is generally only used on a server.
  // Should be called after Open(). Returns a net error code.
  int Bind(const IPEndPoint& address);

  // Put this socket on listen state with the given |backlog|.
  // Returns a net error code.
  int Listen(int backlog);

  // Accepts incoming connection.
  // Returns a net error code.
  int Accept(std::unique_ptr<TCPSocketPosix>* socket,
             IPEndPoint* address,
             CompletionOnceCallback callback);

  // Connects this socket to the given |address|.
  // Should be called after Open().
  // Returns a net error code.
  int Connect(const IPEndPoint& address, CompletionOnceCallback callback);
  bool IsConnected() const;
  bool IsConnectedAndIdle() const;

  // IO:
  // Multiple outstanding requests are not supported.
  // Full duplex mode (reading and writing at the same time) is supported.

  // Reads from the socket.
  // Returns a net error code.
  int Read(IOBuffer* buf, int buf_len, CompletionOnceCallback callback);
  int ReadIfReady(IOBuffer* buf, int buf_len, CompletionOnceCallback callback);
  int CancelReadIfReady();

  // Writes to the socket.
  // Returns a net error code.
  int Write(IOBuffer* buf,
            int buf_len,
            CompletionOnceCallback callback,
            const NetworkTrafficAnnotationTag& traffic_annotation);

  // Copies the local tcp address into |address| and returns a net error code.
  int GetLocalAddress(IPEndPoint* address) const;

  // Copies the remote tcp code into |address| and returns a net error code.
  int GetPeerAddress(IPEndPoint* address) const;

  // Sets various socket options.
  // The commonly used options for server listening sockets:
  // - AllowAddressReuse().
  int SetDefaultOptionsForServer();
  // The commonly used options for client sockets and accepted sockets:
  // - SetNoDelay(true);
  // - SetKeepAlive(true, 45).
  void SetDefaultOptionsForClient();
  int AllowAddressReuse();
  int SetReceiveBufferSize(int32_t size);
  int SetSendBufferSize(int32_t size);
  bool SetKeepAlive(bool enable, int delay);
  bool SetNoDelay(bool no_delay);

  // Gets the estimated RTT. Returns false if the RTT is
  // unavailable. May also return false when estimated RTT is 0.
#if !BUILDFLAG(TTNET_IMPLEMENT)
  bool GetEstimatedRoundTripTime(base::TimeDelta* out_rtt) const
      WARN_UNUSED_RESULT;
#endif

  // Closes the socket.
  void Close();

  bool IsValid() const;

  // Detachs from the current thread, to allow the socket to be transferred to
  // a new thread. Should only be called when the object is no longer used by
  // the old thread.
  void DetachFromThread();

  // Marks the start/end of a series of connect attempts for logging purpose.
  //
  // TCPClientSocket may attempt to connect to multiple addresses until it
  // succeeds in establishing a connection. The corresponding log will have
  // multiple NetLogEventType::TCP_CONNECT_ATTEMPT entries nested within a
  // NetLogEventType::TCP_CONNECT. These methods set the start/end of
  // NetLogEventType::TCP_CONNECT.
  //
  // TODO(yzshen): Change logging format and let TCPClientSocket log the
  // start/end of a series of connect attempts itself.
  void StartLoggingMultipleConnectAttempts(const AddressList& addresses);
  void EndLoggingMultipleConnectAttempts(int net_error);

  const NetLogWithSource& net_log() const { return net_log_; }

  // Return the underlying SocketDescriptor and clean up this object, which may
  // no longer be used. This method should be used only for testing. No read,
  // write, or accept operations should be pending.
  SocketDescriptor ReleaseSocketDescriptorForTesting();

  // Exposes the underlying socket descriptor for testing its state. Does not
  // release ownership of the descriptor.
  SocketDescriptor SocketDescriptorForTesting() const;

  // Apply |tag| to this socket.
  void ApplySocketTag(const SocketTag& tag);

  // May return nullptr.
  SocketPerformanceWatcher* socket_performance_watcher() const {
    return socket_performance_watcher_.get();
  }

#if BUILDFLAG(TTNET_IMPLEMENT)
  bool GetEstimatedRoundTripTime(base::TimeDelta* out_rtt) WARN_UNUSED_RESULT;
  bool SetTcpKeepAliveOptions(bool keep_alive,
                              int keep_idle,
                              int keep_interval,
                              int keep_count);
  void SetNewSocketTimeoutParam(const SocketTimeoutParam& socket_timeout_param);

  const SocketTimeoutParam& socket_timeout_param() {
    return socket_timeout_param_;
  }

  int32_t GetSocketBufferSize(bool send_buf) const;

#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  SocketDescriptor socket_fd() const;
#endif
#endif

 private:
  void AcceptCompleted(std::unique_ptr<TCPSocketPosix>* tcp_socket,
                       IPEndPoint* address,
                       CompletionOnceCallback callback,
                       int rv);
  int HandleAcceptCompleted(std::unique_ptr<TCPSocketPosix>* tcp_socket,
                            IPEndPoint* address,
                            int rv);
  int BuildTcpSocketPosix(std::unique_ptr<TCPSocketPosix>* tcp_socket,
                          IPEndPoint* address);

  void ConnectCompleted(CompletionOnceCallback callback, int rv);
  int HandleConnectCompleted(int rv);
  void LogConnectBegin(const AddressList& addresses) const;
  void LogConnectEnd(int net_error) const;

  void ReadCompleted(const scoped_refptr<IOBuffer>& buf,
                     CompletionOnceCallback callback,
                     int rv);
  void ReadIfReadyCompleted(CompletionOnceCallback callback, int rv);
  int HandleReadCompleted(IOBuffer* buf, int rv);
  void HandleReadCompletedHelper(int rv);

  void WriteCompleted(const scoped_refptr<IOBuffer>& buf,
                      CompletionOnceCallback callback,
                      int rv);
  int HandleWriteCompleted(IOBuffer* buf, int rv);

  // Notifies |socket_performance_watcher_| of the latest RTT estimate available
  // from the tcp_info struct for this TCP socket.
  void NotifySocketPerformanceWatcher();

#if BUILDFLAG(TTNET_IMPLEMENT)
  SocketTimeoutParam socket_timeout_param_;

  std::unique_ptr<SocketPosixWrapper> socket_;
#else
  std::unique_ptr<SocketPosix> socket_;
#endif
  std::unique_ptr<SocketPosix> accept_socket_;

  // Socket performance statistics (such as RTT) are reported to the
  // |socket_performance_watcher_|. May be nullptr.
  std::unique_ptr<SocketPerformanceWatcher> socket_performance_watcher_;

  bool logging_multiple_connect_attempts_;

  NetLogWithSource net_log_;

  // Current socket tag if |socket_| is valid, otherwise the tag to apply when
  // |socket_| is opened.
  SocketTag tag_;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
 private:
  std::unique_ptr<TTTCPInfoHelper> tt_tcp_info_helper_;
#endif

  DISALLOW_COPY_AND_ASSIGN(TCPSocketPosix);
};

}  // namespace net

#endif  // NET_SOCKET_TCP_SOCKET_POSIX_H_
