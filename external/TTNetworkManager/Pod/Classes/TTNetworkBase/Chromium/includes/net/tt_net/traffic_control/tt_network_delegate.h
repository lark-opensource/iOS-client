// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_TRAFFIC_CONTROL_TT_NETWORK_DELEGATE_H_
#define NET_TTNET_TRAFFIC_CONTROL_TT_NETWORK_DELEGATE_H_

#include "base/single_thread_task_runner.h"
#include "base/values.h"
#include "net/base/network_delegate_impl.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class TTNetworkDelegate : public NetworkDelegateImpl {
 public:
  TTNetworkDelegate();
  ~TTNetworkDelegate() override;

  static void SetOpaque(void* security_callback);
  typedef char* (*tt_security_callback)(const char* const url,
                                        const char* const headers);

#if (defined(OS_WIN) || defined(OS_MAC)) && \
    !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_MSSDK_SUPPORT)
  typedef char* (*tt_security_callback_free)(void* addr);
  static void SetOpaqueFree(void* security_callback_free);
  static tt_security_callback_free GetOpaqueFree();
#endif

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTNetworkDelegateTest;
#endif

  // implement of net::NetworkDelegate
  int OnBeforeStartTransaction(URLRequest* request,
                               CompletionOnceCallback callback,
                               HttpRequestHeaders* headers) override;
  int OnHeadersReceived(
      URLRequest* request,
      CompletionOnceCallback callback,
      const HttpResponseHeaders* original_response_headers,
      scoped_refptr<HttpResponseHeaders>* override_response_headers,
      const IPEndPoint& remote_endpoint,
      base::Optional<GURL>* preserve_fragment_on_redirect_url) override;
  void OnBeforeRedirect(URLRequest* request, const GURL& new_location) override;
  void OnResponseStarted(URLRequest* request, int net_error) override;
  void OnCompleted(URLRequest* request, bool started, int net_error) override;
  void OnURLRequestDestroyed(URLRequest* request) override;
  void OnPACScriptError(int line_number, const base::string16& error) override;
  bool OnCanGetCookies(const URLRequest& request,
                       bool allowed_from_caller) override;
  bool OnCanSetCookie(const URLRequest& request,
                      const net::CanonicalCookie& cookie,
                      CookieOptions* options,
                      bool allowed_from_caller) override;
  int OnBeforeURLRequest(URLRequest* request,
                         CompletionOnceCallback callback,
                         GURL* new_url) override;
  void MaybeRemoveHostResolverCacheEntry(const URLRequest* request,
                                         int net_error);

  bool ShouldInvalidateDnsResultForError(int error) const;

  bool ShouldBypassURLDispatch(const URLRequest* request) const;

  DISALLOW_COPY_AND_ASSIGN(TTNetworkDelegate);
};

}  // namespace net
#endif  // NET_TTNET_TRAFFIC_CONTROL_TT_NETWORK_DELEGATE_H_
