// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_URL_REQUEST_URL_FETCHER_DELEGATE_H_
#define NET_URL_REQUEST_URL_FETCHER_DELEGATE_H_

#include <stdint.h>

#include <memory>
#include <string>

#include "base/ttnet_implement_buildflags.h"
#include "net/base/net_export.h"

namespace net {

class URLFetcher;
#if BUILDFLAG(TTNET_IMPLEMENT)
class HttpRequestHeaders;
class HttpResponseInfo;
struct RedirectInfo;
class SSLInfo;
class URLRequest;
#endif

// A delegate interface for users of URLFetcher.
class TTNET_IMPLEMENT_EXPORT NET_EXPORT URLFetcherDelegate {
 public:
  // This will be called when the URL has been fetched, successfully or not.
  // Use accessor methods on |source| to get the results.
  virtual void OnURLFetchComplete(const URLFetcher* source) = 0;

  // This will be called when some part of the response is read. |current|
  // denotes the number of bytes received up to the call, and |total| is the
  // expected total size of the response (or -1 if not determined).
  // |current_network_bytes| denotes the number of network bytes received
  // up to the call, excluding redirect bodies, SSL and proxy handshakes.
  virtual void OnURLFetchDownloadProgress(const URLFetcher* source,
                                          int64_t current,
                                          int64_t total,
                                          int64_t current_network_bytes);

  // This will be called when uploading of POST or PUT requests proceeded.
  // |current| denotes the number of bytes sent so far, and |total| is the
  // total size of uploading data (or -1 if chunked upload is enabled).
  virtual void OnURLFetchUploadProgress(const URLFetcher* source,
                                        int64_t current,
                                        int64_t total);

#if BUILDFLAG(TTNET_IMPLEMENT)
  // This will be called When the response headers has been received without
  // network level errors. Use accessor methods on |source| to get the results.
  virtual void OnURLResponseStarted(const URLFetcher* source) {}

  virtual void OnURLRedirectReceived(const URLFetcher* source,
                                     const RedirectInfo& redirect_info,
                                     const HttpResponseInfo& response_info) {}

  virtual void OnTransactionAboutToStart(const URLFetcher* source,
                                         const std::string& url,
                                         HttpRequestHeaders* headers) {}

  virtual bool SkipSSLCertificateError(URLRequest* request,
                                       const SSLInfo& ssl_info,
                                       bool fatal);

#endif

 protected:
  virtual ~URLFetcherDelegate();
};

}  // namespace net

#endif  // NET_URL_REQUEST_URL_FETCHER_DELEGATE_H_
