// Copyright 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_SOCKET_POSIX_WRAPPER_H_
#define NET_TT_NET_BASE_SOCKET_POSIX_WRAPPER_H_

#include <memory>

#include "base/timer/timer.h"
#include "net/base/completion_once_callback.h"
#include "net/base/sockaddr_storage.h"
#include "net/socket/socket_descriptor.h"
#include "net/socket/socket_posix.h"
#include "net/tt_net/base/socket_timeout_param.h"

namespace net {

class IOBuffer;
class IPEndPoint;

// This is the wrapper class of SocketPosix. Added logic for socket level can be
// written in this wrapper, for example, timeout control or retry.
class NET_EXPORT_PRIVATE SocketPosixWrapper {
 public:
  SocketPosixWrapper();

  SocketPosixWrapper(std::unique_ptr<base::OneShotTimer> write_timer,
                     std::unique_ptr<base::OneShotTimer> read_timer);
  virtual ~SocketPosixWrapper();

  void Reset(SocketPosix* socket_posix);

  // Opens a socket and returns net::OK if |address_family| is AF_INET, AF_INET6
  // or AF_UNIX. Otherwise, it does DCHECK() and returns a net error.
  int Open(int address_family);
  // Takes ownership of |socket|.
  int AdoptConnectedSocket(SocketDescriptor socket,
                           const SockaddrStorage& peer_address);
  int AdoptUnconnectedSocket(SocketDescriptor socket);
  // Releases ownership of |socket_fd_| to caller.
  SocketDescriptor ReleaseConnectedSocket();

  int Bind(const SockaddrStorage& address);

  int Listen(int backlog);
  int Accept(std::unique_ptr<SocketPosix>* socket,
             CompletionOnceCallback callback);

  // Connects socket. On non-ERR_IO_PENDING error, sets errno and returns a net
  // error code. On ERR_IO_PENDING, |callback| is called with a net error code,
  // not errno, though errno is set if connect event happens with error.
  // TODO(byungchul): Need more robust way to pass system errno.
  int Connect(const SockaddrStorage& address, CompletionOnceCallback callback);
  bool IsConnected() const;
  bool IsConnectedAndIdle() const;

  // Multiple outstanding requests of the same type are not supported.
  // Full duplex mode (reading and writing at the same time) is supported.
  // On error which is not ERR_IO_PENDING, sets errno and returns a net error
  // code. On ERR_IO_PENDING, |callback| is called with a net error code, not
  // errno, though errno is set if read or write events happen with error.
  // TODO(byungchul): Need more robust way to pass system errno.
  int Read(IOBuffer* buf, int buf_len, CompletionOnceCallback callback);
  int ReadIfReady(IOBuffer* buf, int buf_len, CompletionOnceCallback callback);
  int CancelReadIfReady();
  int Write(IOBuffer* buf,
            int buf_len,
            CompletionOnceCallback callback,
            const NetworkTrafficAnnotationTag& traffic_annotation);

  // Waits for next write event. This is called by TCPSocketPosix for TCP
  // fastopen after sending first data. Returns ERR_IO_PENDING if it starts
  // waiting for write event successfully. Otherwise, returns a net error code.
  // It must not be called after Write() because Write() calls it internally.
  int WaitForWrite(IOBuffer* buf, int buf_len, CompletionOnceCallback callback);

  int GetLocalAddress(SockaddrStorage* address) const;
  int GetPeerAddress(SockaddrStorage* address) const;
  void SetPeerAddress(const SockaddrStorage& address);
  // Returns true if peer address has been set regardless of socket state.
  bool HasPeerAddress() const;

  void Close();

  // Detachs from the current thread, to allow the socket to be transferred to
  // a new thread. Should only be called when the object is no longer used by
  // the old thread.
  void DetachFromThread();

  SocketDescriptor socket_fd() const { return socket_posix_->socket_fd(); }

  void set_socket_timeout_param(
      const SocketTimeoutParam& socket_timeout_param) {
    socket_timeout_param_ = socket_timeout_param;
  }

 private:
  void OnReadComplete(int rv);
  void OnWriteComplete(int rv);

  void OnReadTimeout(int rv);
  void OnWriteTimeout(int rv);

  std::unique_ptr<SocketPosix> socket_posix_;

  SocketTimeoutParam socket_timeout_param_;

  std::unique_ptr<base::OneShotTimer> read_timer_;
  std::unique_ptr<base::OneShotTimer> write_timer_;

  // External callbacks:
  CompletionOnceCallback read_callback_;
  CompletionOnceCallback write_callback_;

  DISALLOW_COPY_AND_ASSIGN(SocketPosixWrapper);
};

}  // namespace net

#endif  // NET_TT_NET_BASE_SOCKET_POSIX_WRAPPER_H_
