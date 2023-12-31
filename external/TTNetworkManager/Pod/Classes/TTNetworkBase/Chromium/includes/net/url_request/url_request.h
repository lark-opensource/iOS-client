// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_URL_REQUEST_URL_REQUEST_H_
#define NET_URL_REQUEST_URL_REQUEST_H_

#include <stdint.h>

#include <memory>
#include <string>
#include <vector>

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/optional.h"
#include "base/strings/string16.h"
#include "base/supports_user_data.h"
#include "base/threading/thread_checker.h"
#include "base/time/time.h"
#include "net/base/auth.h"
#include "net/base/ip_endpoint.h"
#include "net/base/isolation_info.h"
#include "net/base/load_states.h"
#include "net/base/load_timing_info.h"
#include "net/base/net_error_details.h"
#include "net/base/net_export.h"
#include "net/base/network_delegate.h"
#include "net/base/privacy_mode.h"
#include "net/base/proxy_server.h"
#include "net/base/request_priority.h"
#include "net/base/upload_progress.h"
#include "net/cookies/canonical_cookie.h"
#include "net/cookies/site_for_cookies.h"
#include "net/http/http_raw_request_headers.h"
#include "net/http/http_request_headers.h"
#include "net/http/http_response_headers.h"
#include "net/http/http_response_info.h"
#include "net/log/net_log_event_type.h"
#include "net/log/net_log_with_source.h"
#include "net/net_buildflags.h"
#include "net/socket/connection_attempts.h"
#include "net/socket/socket_tag.h"
#include "net/traffic_annotation/network_traffic_annotation.h"
#include "net/url_request/redirect_info.h"
#include "net/url_request/referrer_policy.h"
#include "url/gurl.h"
#include "url/origin.h"

#if BUILDFLAG(TTNET_IMPLEMENT)
#include "base/timer/timer.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/base/socket_pool_info.h"
#include "net/tt_net/base/socket_timeout_param.h"
#include "net/tt_net/base/tt_request_type_flags.h"
#include "net/tt_net/base/ttnet_basic_request_info.h"
#include "net/tt_net/url_dispatcher/dispatch_action_info.h"
#endif

namespace base {
class Value;
}  // namespace base

namespace net {

class CookieOptions;
class IOBuffer;
struct LoadTimingInfo;
struct RedirectInfo;
class SSLCertRequestInfo;
class SSLInfo;
class SSLPrivateKey;
struct TransportInfo;
class UploadDataStream;
class URLRequestContext;
class URLRequestJob;
class X509Certificate;

#if BUILDFLAG(TTNET_IMPLEMENT)
struct SocketTimeoutParam;
#endif

//-----------------------------------------------------------------------------
// A class  representing the asynchronous load of a data stream from an URL.
//
// The lifetime of an instance of this class is completely controlled by the
// consumer, and the instance is not required to live on the heap or be
// allocated in any special way.  It is also valid to delete an URLRequest
// object during the handling of a callback to its delegate.  Of course, once
// the URLRequest is deleted, no further callbacks to its delegate will occur.
//
// NOTE: All usage of all instances of this class should be on the same thread.
//
class NET_EXPORT URLRequest : public base::SupportsUserData {
 public:
  // Callback function implemented by protocol handlers to create new jobs.
  // The factory may return NULL to indicate an error, which will cause other
  // factories to be queried.  If no factory handles the request, then the
  // default job will be used.
  typedef URLRequestJob*(ProtocolFactory)(URLRequest* request,
                                          const std::string& scheme);

  // Max number of http redirects to follow. The Fetch spec says: "If
  // request's redirect count is twenty, return a network error."
  // https://fetch.spec.whatwg.org/#http-redirect-fetch
  static constexpr int kMaxRedirects = 20;

  // The delegate's methods are called from the message loop of the thread
  // on which the request's Start() method is called. See above for the
  // ordering of callbacks.
  //
  // The callbacks will be called in the following order:
  //   Start()
  //    - OnConnected* (zero or more calls, see method comment)
  //    - OnCertificateRequested* (zero or more calls, if the SSL server and/or
  //      SSL proxy requests a client certificate for authentication)
  //    - OnSSLCertificateError* (zero or one call, if the SSL server's
  //      certificate has an error)
  //    - OnReceivedRedirect* (zero or more calls, for the number of redirects)
  //    - OnAuthRequired* (zero or more calls, for the number of
  //      authentication failures)
  //    - OnResponseStarted
  //   Read() initiated by delegate
  //    - OnReadCompleted* (zero or more calls until all data is read)
  //
  // Read() must be called at least once. Read() returns bytes read when it
  // completes immediately, and a negative error value if an IO is pending or if
  // there is an error.
  class NET_EXPORT Delegate {
   public:
    // Called each time a connection is obtained, before any data is sent.
    //
    // |request| is never nullptr. Caller retains ownership.
    //
    // |info| describes the newly-obtained connection.
    //
    // This may be called several times if the request creates multiple HTTP
    // transactions, e.g. if the request is redirected. It may also be called
    // several times per transaction, e.g. if the connection is retried, after
    // each HTTP auth challenge, or for split HTTP range requests.
    //
    // If this returns an error, the request fails with the given error.
    // Otherwise the request continues unimpeded.
    // Must not return ERR_IO_PENDING.
    //
    // TODO(crbug.com/591068): Allow ERR_IO_PENDING for a potentially-slow
    // CORS-RFC1918 preflight check.
    virtual int OnConnected(URLRequest* request, const TransportInfo& info);

    // Called upon receiving a redirect.  The delegate may call the request's
    // Cancel method to prevent the redirect from being followed.  Since there
    // may be multiple chained redirects, there may also be more than one
    // redirect call.
    //
    // When this function is called, the request will still contain the
    // original URL, the destination of the redirect is provided in
    // |redirect_info.new_url|.  If the delegate does not cancel the request
    // and |*defer_redirect| is false, then the redirect will be followed, and
    // the request's URL will be changed to the new URL.  Otherwise if the
    // delegate does not cancel the request and |*defer_redirect| is true, then
    // the redirect will be followed once FollowDeferredRedirect is called
    // on the URLRequest.
    //
    // The caller must set |*defer_redirect| to false, so that delegates do not
    // need to set it if they are happy with the default behavior of not
    // deferring redirect.
    virtual void OnReceivedRedirect(URLRequest* request,
                                    const RedirectInfo& redirect_info,
                                    bool* defer_redirect);

    // Called when we receive an authentication failure.  The delegate should
    // call request->SetAuth() with the user's credentials once it obtains them,
    // or request->CancelAuth() to cancel the login and display the error page.
    // When it does so, the request will be reissued, restarting the sequence
    // of On* callbacks.
    virtual void OnAuthRequired(URLRequest* request,
                                const AuthChallengeInfo& auth_info);

    // Called when we receive an SSL CertificateRequest message for client
    // authentication.  The delegate should call
    // request->ContinueWithCertificate() with the client certificate the user
    // selected and its private key, or request->ContinueWithCertificate(NULL,
    // NULL)
    // to continue the SSL handshake without a client certificate.
    virtual void OnCertificateRequested(URLRequest* request,
                                        SSLCertRequestInfo* cert_request_info);

    // Called when using SSL and the server responds with a certificate with
    // an error, for example, whose common name does not match the common name
    // we were expecting for that host.  The delegate should either do the
    // safe thing and Cancel() the request or decide to proceed by calling
    // ContinueDespiteLastError().  cert_error is a ERR_* error code
    // indicating what's wrong with the certificate.
    // If |fatal| is true then the host in question demands a higher level
    // of security (due e.g. to HTTP Strict Transport Security, user
    // preference, or built-in policy). In this case, errors must not be
    // bypassable by the user.
    virtual void OnSSLCertificateError(URLRequest* request,
                                       int net_error,
                                       const SSLInfo& ssl_info,
                                       bool fatal);

    // After calling Start(), the delegate will receive an OnResponseStarted
    // callback when the request has completed. |net_error| will be set to OK
    // or an actual net error.  On success, all redirects have been
    // followed and the final response is beginning to arrive.  At this point,
    // meta data about the response is available, including for example HTTP
    // response headers if this is a request for a HTTP resource.
    virtual void OnResponseStarted(URLRequest* request, int net_error);

    // Called when the a Read of the response body is completed after an
    // IO_PENDING status from a Read() call.
    // The data read is filled into the buffer which the caller passed
    // to Read() previously.
    //
    // If an error occurred, |bytes_read| will be set to the error.
    virtual void OnReadCompleted(URLRequest* request, int bytes_read) = 0;

#if BUILDFLAG(TTNET_IMPLEMENT)
    virtual void OnTransactionAboutToStart(URLRequest* request,
                                           HttpRequestHeaders* headers);
#endif

   protected:
    virtual ~Delegate() {}
  };

  // If destroyed after Start() has been called but while IO is pending,
  // then the request will be effectively canceled and the delegate
  // will not have any more of its methods called.
  ~URLRequest() override;

  // Changes the default cookie policy from allowing all cookies to blocking all
  // cookies. Embedders that want to implement a more flexible policy should
  // change the default to blocking all cookies, and provide a NetworkDelegate
  // with the URLRequestContext that maintains the CookieStore.
  // The cookie policy default has to be set before the first URLRequest is
  // started. Once it was set to block all cookies, it cannot be changed back.
  static void SetDefaultCookiePolicyToBlock();

  // The original url is the url used to initialize the request, and it may
  // differ from the url if the request was redirected.
  const GURL& original_url() const { return url_chain_.front(); }
  // The chain of urls traversed by this request.  If the request had no
  // redirects, this vector will contain one element.
  const std::vector<GURL>& url_chain() const { return url_chain_; }
  const GURL& url() const { return url_chain_.back(); }

  // The URL that should be consulted for the third-party cookie blocking
  // policy, as defined in Section 2.1.1 and 2.1.2 of
  // https://tools.ietf.org/html/draft-ietf-httpbis-cookie-same-site.
  //
  // WARNING: This URL must only be used for the third-party cookie blocking
  //          policy. It MUST NEVER be used for any kind of SECURITY check.
  //
  //          For example, if a top-level navigation is redirected, the
  //          first-party for cookies will be the URL of the first URL in the
  //          redirect chain throughout the whole redirect. If it was used for
  //          a security check, an attacker might try to get around this check
  //          by starting from some page that redirects to the
  //          host-to-be-attacked.
  //
  const SiteForCookies& site_for_cookies() const { return site_for_cookies_; }
  // This method may only be called before Start().
  void set_site_for_cookies(const SiteForCookies& site_for_cookies);

  // Sets IsolationInfo for the request, which affects whether SameSite cookies
  // are sent, what NetworkIsolationKey is used for cached resources, and how
  // that behavior changes when following redirects. This may only be changed
  // before Start() is called.
  //
  // TODO(https://crbug.com/1060631): This isn't actually used yet for SameSite
  // cookies. Update consumers and fix that.
  void set_isolation_info(const IsolationInfo& isolation_info) {
    isolation_info_ = isolation_info;
  }
  const IsolationInfo& isolation_info() const { return isolation_info_; }

  // Indicate whether SameSite cookies should be attached even though the
  // request is cross-site.
  bool force_ignore_site_for_cookies() const {
    return force_ignore_site_for_cookies_;
  }
  void set_force_ignore_site_for_cookies(bool attach) {
    force_ignore_site_for_cookies_ = attach;
  }

  // The first-party URL policy to apply when updating the first party URL
  // during redirects. The first-party URL policy may only be changed before
  // Start() is called.
  RedirectInfo::FirstPartyURLPolicy first_party_url_policy() const {
    return first_party_url_policy_;
  }
  void set_first_party_url_policy(
      RedirectInfo::FirstPartyURLPolicy first_party_url_policy);

  // The origin of the context which initiated the request. This is distinct
  // from the "first party for cookies" discussed above in a number of ways:
  //
  // 1. The request's initiator does not change during a redirect. If a form
  //    submission from `https://example.com/` redirects through a number of
  //    sites before landing on `https://not-example.com/`, the initiator for
  //    each of those requests will be `https://example.com/`.
  //
  // 2. The request's initiator is the origin of the frame or worker which made
  //    the request, even for top-level navigations. That is, if
  //    `https://example.com/`'s form submission is made in the top-level frame,
  //    the first party for cookies would be the target URL's origin. The
  //    initiator remains `https://example.com/`.
  //
  // This value is used to perform the cross-origin check specified in Section
  // 4.3 of https://tools.ietf.org/html/draft-ietf-httpbis-cookie-same-site.
  //
  // Note: the initiator can be null for browser-initiated top level
  // navigations. This is different from a unique Origin (e.g. in sandboxed
  // iframes).
  const base::Optional<url::Origin>& initiator() const { return initiator_; }
  // This method may only be called before Start().
  void set_initiator(const base::Optional<url::Origin>& initiator);

  // The request method, as an uppercase string.  "GET" is the default value.
  // The request method may only be changed before Start() is called and
  // should only be assigned an uppercase value.
  const std::string& method() const { return method_; }
  void set_method(const std::string& method);

#if BUILDFLAG(ENABLE_REPORTING)
  // Reporting upload nesting depth of this request.
  //
  // If the request is not a Reporting upload, the depth is 0.
  //
  // If the request is a Reporting upload, the depth is the max of the depth
  // of the requests reported within it plus 1. (Non-NEL reports are
  // considered to have depth 0.)
  int reporting_upload_depth() const { return reporting_upload_depth_; }
  void set_reporting_upload_depth(int reporting_upload_depth);
#endif

  // The referrer URL for the request
  const std::string& referrer() const { return referrer_; }
  // Sets the referrer URL for the request. Can only be changed before Start()
  // is called. |referrer| is sanitized to remove URL fragment, user name and
  // password. If a referrer policy is set via set_referrer_policy(), then
  // |referrer| should obey the policy; if it doesn't, it will be cleared when
  // the request is started. The referrer URL may be suppressed or changed
  // during the course of the request, for example because of a referrer policy
  // set with set_referrer_policy().
  void SetReferrer(const std::string& referrer);

  // The referrer policy to apply when updating the referrer during redirects.
  // The referrer policy may only be changed before Start() is called. Any
  // referrer set via SetReferrer() is expected to obey the policy set via
  // set_referrer_policy(); otherwise the referrer will be cleared when the
  // request is started.
  ReferrerPolicy referrer_policy() const { return referrer_policy_; }
  void set_referrer_policy(ReferrerPolicy referrer_policy);

  // Sets whether credentials are allowed.
  // If credentials are allowed, the request will send and save HTTP
  // cookies, as well as authentication to the origin server. If not,
  // they will not be sent, however proxy-level authentication will
  // still occur. Setting this will force the LOAD_DO_NOT_SAVE_COOKIES field to
  // be set in |load_flags_|. See https://crbug.com/799935.
  void set_allow_credentials(bool allow_credentials);
  bool allow_credentials() const { return allow_credentials_; }

  // Sets the upload data.
  void set_upload(std::unique_ptr<UploadDataStream> upload);

  // Gets the upload data.
  const UploadDataStream* get_upload_for_testing() const;

  // Returns true if the request has a non-empty message body to upload.
  bool has_upload() const;

  // Set or remove a extra request header.  These methods may only be called
  // before Start() is called, or between receiving a redirect and trying to
  // follow it.
  void SetExtraRequestHeaderByName(const std::string& name,
                                   const std::string& value,
                                   bool overwrite);
  void RemoveRequestHeaderByName(const std::string& name);

  // Sets all extra request headers.  Any extra request headers set by other
  // methods are overwritten by this method.  This method may only be called
  // before Start() is called.  It is an error to call it later.
  void SetExtraRequestHeaders(const HttpRequestHeaders& headers);

  const HttpRequestHeaders& extra_request_headers() const {
    return extra_request_headers_;
  }

#if BUILDFLAG(TTNET_IMPLEMENT)
  // Get control operations from http header. control header starts with
  // "x-ttnet"
  void ParseAndSetOperationsFrom(const HttpRequestHeaders& headers);
  const std::map<std::string, std::string>& GetControlHeaders() const;
  int GetTargetHttpProtoType() const;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
  void SetSessionMaxRecvWindowSize(int32_t session_max_recv_window_size);
  const std::string& GetThrottleLevel() const { return throttle_level_; }

 protected:
  friend class ThrottleMonitor;

 private:
  int32_t session_max_recv_window_size_{-1};
  std::string throttle_level_;

 public:
#endif
#endif

  // Gets the total amount of data received from network after SSL decoding and
  // proxy handling. Pertains only to the last URLRequestJob issued by this
  // URLRequest, i.e. reset on redirects, but not reset when multiple roundtrips
  // are used for range requests or auth.
  int64_t GetTotalReceivedBytes() const;

  // Gets the total amount of data sent over the network before SSL encoding and
  // proxy handling. Pertains only to the last URLRequestJob issued by this
  // URLRequest, i.e. reset on redirects, but not reset when multiple roundtrips
  // are used for range requests or auth.
  int64_t GetTotalSentBytes() const;

  // The size of the response body before removing any content encodings.
  // Does not include redirects or sub-requests issued at lower levels (range
  // requests or auth). Only includes bytes which have been read so far,
  // including bytes from the cache.
  int64_t GetRawBodyBytes() const;

  // Returns the current load state for the request. The returned value's
  // |param| field is an optional parameter describing details related to the
  // load state. Not all load states have a parameter.
  LoadStateWithParam GetLoadState() const;

  // Returns a partial representation of the request's state as a value, for
  // debugging.
  base::Value GetStateAsValue() const;

  // Logs information about the what external object currently blocking the
  // request.  LogUnblocked must be called before resuming the request.  This
  // can be called multiple times in a row either with or without calling
  // LogUnblocked between calls.  |blocked_by| must not be NULL or have length
  // 0.
  void LogBlockedBy(const char* blocked_by);

  // Just like LogBlockedBy, but also makes GetLoadState return source as the
  // |param| in the value returned by GetLoadState.  Calling LogUnblocked or
  // LogBlockedBy will clear the load param.  |blocked_by| must not be NULL or
  // have length 0.
  void LogAndReportBlockedBy(const char* blocked_by);

  // Logs that the request is no longer blocked by the last caller to
  // LogBlockedBy.
  void LogUnblocked();

  // Returns the current upload progress in bytes. When the upload data is
  // chunked, size is set to zero, but position will not be.
  UploadProgress GetUploadProgress() const;

  // Get response header(s) by name.  This method may only be called
  // once the delegate's OnResponseStarted method has been called.  Headers
  // that appear more than once in the response are coalesced, with values
  // separated by commas (per RFC 2616). This will not work with cookies since
  // comma can be used in cookie values.
  void GetResponseHeaderByName(const std::string& name,
                               std::string* value) const;

  // The time when |this| was constructed.
  base::TimeTicks creation_time() const { return creation_time_; }

  // The time at which the returned response was requested.  For cached
  // responses, this is the last time the cache entry was validated.
  const base::Time& request_time() const { return response_info_.request_time; }

  // The time at which the returned response was generated.  For cached
  // responses, this is the last time the cache entry was validated.
  const base::Time& response_time() const {
    return response_info_.response_time;
  }

  // Indicate if this response was fetched from disk cache.
  bool was_cached() const { return response_info_.was_cached; }

  // Returns true if the URLRequest was delivered over SPDY.
  bool was_fetched_via_spdy() const {
    return response_info_.was_fetched_via_spdy;
  }

  // Returns the host and port that the content was fetched from.  See
  // http_response_info.h for caveats relating to cached content.
  IPEndPoint GetResponseRemoteEndpoint() const;

  // Get all response headers, as a HttpResponseHeaders object.  See comments
  // in HttpResponseHeaders class as to the format of the data.
  HttpResponseHeaders* response_headers() const;

  // Get the SSL connection info.
  const SSLInfo& ssl_info() const { return response_info_.ssl_info; }

  const base::Optional<AuthChallengeInfo>& auth_challenge_info() const;

  // Gets timing information related to the request.  Events that have not yet
  // occurred are left uninitialized.  After a second request starts, due to
  // a redirect or authentication, values will be reset.
  //
  // LoadTimingInfo only contains ConnectTiming information and socket IDs for
  // non-cached HTTP responses.
  void GetLoadTimingInfo(LoadTimingInfo* load_timing_info) const;

  // Gets the networkd error details of the most recent origin that the network
  // stack makes the request to.
  void PopulateNetErrorDetails(NetErrorDetails* details) const;

  // Gets the remote endpoint of the most recent socket that the network stack
  // used to make this request.
  //
  // Note that GetResponseRemoteEndpoint returns the |socket_address| field from
  // HttpResponseInfo, which is only populated once the response headers are
  // received, and can return cached values for cache revalidation requests.
  // GetTransactionRemoteEndpoint will only return addresses from the current
  // request.
  //
  // Returns true and fills in |endpoint| if the endpoint is available; returns
  // false and leaves |endpoint| unchanged if it is unavailable.
  bool GetTransactionRemoteEndpoint(IPEndPoint* endpoint) const;

  // Get the mime type.  This method may only be called once the delegate's
  // OnResponseStarted method has been called.
  void GetMimeType(std::string* mime_type) const;

  // Get the charset (character encoding).  This method may only be called once
  // the delegate's OnResponseStarted method has been called.
  void GetCharset(std::string* charset) const;

  // Returns the HTTP response code (e.g., 200, 404, and so on).  This method
  // may only be called once the delegate's OnResponseStarted method has been
  // called.  For non-HTTP requests, this method returns -1.
  int GetResponseCode() const;

  // Get the HTTP response info in its entirety.
  const HttpResponseInfo& response_info() const { return response_info_; }

  // Access the LOAD_* flags modifying this request (see load_flags.h).
  int load_flags() const { return load_flags_; }

  // Returns PrivacyMode that should be used for the request. Updated every time
  // the request is redirected.
  PrivacyMode privacy_mode() const { return privacy_mode_; }

  // Returns whether secure DNS should be disabled for the request.
  bool disable_secure_dns() const { return disable_secure_dns_; }

  void set_maybe_sent_cookies(CookieAccessResultList cookies);
  void set_maybe_stored_cookies(CookieAndLineAccessResultList cookies);

  // These lists contain a list of cookies that are associated with the given
  // request, both those that were sent and accepted, and those that were
  // removed or flagged from the request before use. The status indicates
  // whether they were actually used (INCLUDE), or the reason they were removed
  // or flagged. They are cleared on redirects and other request restarts that
  // cause sent cookies to be recomputed / new cookies to potentially be
  // received (such as calling SetAuth() to send HTTP auth credentials, but not
  // calling ContinueWithCertification() to respond to client cert challenges),
  // and only contain the cookies relevant to the most recent roundtrip.

  // Populated while the http request is being built.
  const CookieAccessResultList& maybe_sent_cookies() const {
    return maybe_sent_cookies_;
  }
  // Populated after the response headers are received.
  const CookieAndLineAccessResultList& maybe_stored_cookies() const {
    return maybe_stored_cookies_;
  }

  // The new flags may change the IGNORE_LIMITS flag only when called
  // before Start() is called, it must only set the flag, and if set,
  // the priority of this request must already be MAXIMUM_PRIORITY.
  void SetLoadFlags(int flags);

  // Sets whether secure DNS should be disabled for the request.
  void SetDisableSecureDns(bool disable_secure_dns);

  // Returns true if the request is "pending" (i.e., if Start() has been called,
  // and the response has not yet been called).
  bool is_pending() const { return is_pending_; }

  // Returns true if the request is in the process of redirecting to a new
  // URL but has not yet initiated the new request.
  bool is_redirecting() const { return is_redirecting_; }

  // This method is called to start the request.  The delegate will receive
  // a OnResponseStarted callback when the request is started.  The request
  // must have a delegate set before this method is called.
  void Start();

  // This method may be called at any time after Start() has been called to
  // cancel the request.  This method may be called many times, and it has
  // no effect once the response has completed.  It is guaranteed that no
  // methods of the delegate will be called after the request has been
  // cancelled, except that this may call the delegate's OnReadCompleted()
  // during the call to Cancel itself. Returns |ERR_ABORTED| or other net error
  // if there was one.
  int Cancel();

  // Cancels the request and sets the error to |error|, unless the request
  // already failed with another error code (see net_error_list.h). Returns
  // final network error code.
  int CancelWithError(int error);

  // Cancels the request and sets the error to |error| (see net_error_list.h
  // for values) and attaches |ssl_info| as the SSLInfo for that request.  This
  // is useful to attach a certificate and certificate error to a canceled
  // request.
  void CancelWithSSLError(int error, const SSLInfo& ssl_info);

  // Read initiates an asynchronous read from the response, and must only be
  // called after the OnResponseStarted callback is received with a net::OK. If
  // data is available, length and the data will be returned immediately. If the
  // request has failed, an error code will be returned. If data is not yet
  // available, Read returns net::ERR_IO_PENDING, and the Delegate's
  // OnReadComplete method will be called asynchronously with the result of the
  // read, unless the URLRequest is canceled.
  //
  // The |buf| parameter is a buffer to receive the data. If the operation
  // completes asynchronously, the implementation will reference the buffer
  // until OnReadComplete is called. The buffer must be at least |max_bytes| in
  // length.
  //
  // The |max_bytes| parameter is the maximum number of bytes to read.
  int Read(IOBuffer* buf, int max_bytes);

  // This method may be called to follow a redirect that was deferred in
  // response to an OnReceivedRedirect call. If non-null,
  // |modified_headers| are changes applied to the request headers after
  // updating them for the redirect.
  void FollowDeferredRedirect(
      const base::Optional<std::vector<std::string>>& removed_headers,
      const base::Optional<net::HttpRequestHeaders>& modified_headers);

  // One of the following two methods should be called in response to an
  // OnAuthRequired() callback (and only then).
  // SetAuth will reissue the request with the given credentials.
  // CancelAuth will give up and display the error page.
  void SetAuth(const AuthCredentials& credentials);
  void CancelAuth();

  // This method can be called after the user selects a client certificate to
  // instruct this URLRequest to continue with the request with the
  // certificate.  Pass NULL if the user doesn't have a client certificate.
  void ContinueWithCertificate(scoped_refptr<X509Certificate> client_cert,
                               scoped_refptr<SSLPrivateKey> client_private_key);

  // This method can be called after some error notifications to instruct this
  // URLRequest to ignore the current error and continue with the request.  To
  // cancel the request instead, call Cancel().
  void ContinueDespiteLastError();

  // Used to specify the context (cookie store, cache) for this request.
  const URLRequestContext* context() const;

  // Returns context()->network_delegate().
  NetworkDelegate* network_delegate() const;

  const NetLogWithSource& net_log() const { return net_log_; }

  // Returns the expected content size if available
  int64_t GetExpectedContentSize() const;

  // Returns the priority level for this request.
  RequestPriority priority() const { return priority_; }

  // Sets the priority level for this request and any related
  // jobs. Must not change the priority to anything other than
  // MAXIMUM_PRIORITY if the IGNORE_LIMITS load flag is set.
  void SetPriority(RequestPriority priority);

  void set_received_response_content_length(int64_t received_content_length) {
    received_response_content_length_ = received_content_length;
  }

  // The number of bytes in the raw response body (before any decompression,
  // etc.). This is only available after the final Read completes. Not available
  // for FTP responses.
  int64_t received_response_content_length() const {
    return received_response_content_length_;
  }

  // Available when the request headers are sent, which is before the more
  // general response_info() is available.
  const ProxyServer& proxy_server() const { return proxy_server_; }

  // Gets the connection attempts made in the process of servicing this
  // URLRequest. Only guaranteed to be valid if called after the request fails
  // or after the response headers are received.
  void GetConnectionAttempts(ConnectionAttempts* out) const;

  // Gets the over the wire raw header size of the response after https
  // encryption, 0 for cached responses.
  int raw_header_size() const { return raw_header_size_; }

  const NetworkTrafficAnnotationTag& traffic_annotation() const {
    return traffic_annotation_;
  }

#if BUILDFLAG(TTNET_IMPLEMENT)
  std::string GetNot2XXReason() const;

  bool IsStartWithOffline() const { return start_with_offline_; }

  NetworkChangeNotifier::ConnectionType GetStartNetType() const {
    return start_net_type_;
  }

  // Collect the request log before request or request job ended.
  void DoCollectRequestLog();

  int64_t GetFormatRequestLogCost() const { return format_request_log_cost_; }

  // Gets the remote endpoint of the most recent socket that the network stack
  // used to make this request.
  //
  // Note that GetSocketAddress returns the |socket_address| field from
  // HttpResponseInfo, which is only populated once the response headers are
  // received, and can return cached values for cache revalidation requests.
  // GetRemoteEndpoint will only return addresses from the current request.
  //
  // Returns true and fills in |endpoint| if the endpoint is available; returns
  // false and leaves |endpoint| unchanged if it is unavailable.
  bool GetRemoteEndpoint(IPEndPoint* endpoint) const;

  // Gets the retry attempt account for each request.
  int GetRetryAttempts() const;

  // Get the lastest error code which caused internal reset and resend. OK means
  // no reset and resend happend.
  int GetNetErrorForReset() const;
  // Get the error code list which caused internal reset and resend. empty means
  // no reset and resend happend.
  std::vector<int> GetNetErrorListForReset() const;

  // Gets the socket pool related information of the most recent socket that
  // the network stack used to make this request.
  void GetSocketPoolInfo(SocketPoolInfo* socket_pool_info) const;

  void FollowDeferredRedirect(
      const base::Optional<std::vector<std::string>>& removed_headers,
      const base::Optional<net::HttpRequestHeaders>& modified_headers,
      const std::string& redirect_url);

  // Get how this response was handled by the HTTP cache.
  int GetCacheStatus() const {
    return static_cast<int>(response_info_.cache_entry_status);
  }

  const SocketTimeoutParam& socket_timeout_param() const {
    return socket_timeout_param_;
  }

  void set_socket_timeout_param(
      const SocketTimeoutParam& socket_timeout_param) {
    socket_timeout_param_ = socket_timeout_param;
  }

  void set_request_timeout(base::TimeDelta request_timeout) {
    request_timeout_ = request_timeout;
  }

  // Returns the request log content. Should be used after the request end.
  const std::string& request_log() const { return request_log_; }

  // Returns the host and port that the content was fetched from.  See
  // http_response_info.h for caveats relating to cached content.
  HostPortPair GetSocketAddress() const { return HostPortPair(); }

  void set_dispatch_start(base::TimeTicks timeticks) {
    dispatch_start_ = timeticks;
  }

  void set_dispatch_end(base::TimeTicks timeticks) {
    dispatch_end_ = timeticks;
  }

  const std::string& GetSceneType() const { return scene_type_; }

  void SetSceneType(const std::string& scene_type) { scene_type_ = scene_type; }

#if BUILDFLAG(ENABLE_TIKTOK_SUPPORT)
  void set_sandbox_start(base::TimeTicks timeticks) {
    sandbox_start_ = timeticks;
  }

  void set_sandbox_end(base::TimeTicks timeticks) { sandbox_end_ = timeticks; }
#endif

  unsigned int dispatch_priority() const { return dispatch_priority_; }

  void set_dispatch_priority(unsigned int value) { dispatch_priority_ = value; }

  std::vector<DispatchActionInfo>& dispatch_action_chain() {
    return dispatch_action_chain_;
  }

  GURL GetFinalUrl() const;

  std::unordered_map<std::string, std::string>& request_tag() {
    return request_tag_;
  }

#if defined(OS_ANDROID)
  void set_get_cookie_start(base::TimeTicks timeticks) {
    get_cookie_start_ = timeticks;
  }

  void set_get_cookie_end(base::TimeTicks timeticks) {
    get_cookie_end_ = timeticks;
  }
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  void set_delay_time(int delay_mills) { delay_time_ = delay_mills; }
  int delay_time() const { return delay_time_; }
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_API_VERIFICATION)
  int get_ttnet_trace_id_match() const { return ttnet_trace_id_match_; }
  void set_ttnet_trace_id_match(int value) { ttnet_trace_id_match_ = value; }
  bool is_api_source_5xx() const { return is_api_source_5xx_; }
  void enable_api_source_5xx(bool enabled) { is_api_source_5xx_ = enabled; }
#endif

  uint32_t request_type_flags() const { return request_type_flags_; }
  void set_request_type_flags(uint32_t type) { request_type_flags_ |= type; }

  bool is_preprocessed() const { return is_preprocessed_; }
  void set_is_preprocessed(bool value) { is_preprocessed_ = value; }

  bool is_dispatched() const { return is_dispatched_; }
  void set_is_dispatched(bool value) { is_dispatched_ = value; }

  bool is_update_cookie() const { return is_update_cookie_; }
  void set_is_update_cookie(bool value) { is_update_cookie_ = value; }

  void set_request_delay(base::TimeDelta delay) { request_delay_ = delay; }

  void NotifyTransactionAboutToStart(HttpRequestHeaders* headers);

  void set_security_callback_start(base::TimeTicks timeticks) {
    security_callback_start_ = timeticks;
  }

  void set_security_callback_end(base::TimeTicks timeticks) {
    security_callback_end_ = timeticks;
  }

  void set_before_url_request_start(base::TimeTicks timeticks) {
    before_url_request_start_ = timeticks;
  }

  void set_before_url_request_end(base::TimeTicks timeticks) {
    before_url_request_end_ = timeticks;
  }

  void set_before_start_transaction_start(base::TimeTicks timeticks) {
    before_start_transaction_start_ = timeticks;
  }

  void set_before_start_transaction_end(base::TimeTicks timeticks) {
    before_start_transaction_end_ = timeticks;
  }

  void set_on_header_recv_start(base::TimeTicks timeticks) {
    on_header_recv_start_ = timeticks;
  }

  void set_on_header_recv_end(base::TimeTicks timeticks) {
    on_header_recv_end_ = timeticks;
  }

  void set_on_resp_recv_start(base::TimeTicks timeticks) {
    on_resp_recv_start_ = timeticks;
  }

  void set_on_resp_recv_end(base::TimeTicks timeticks) {
    on_resp_recv_end_ = timeticks;
  }

  void set_on_complete_start(base::TimeTicks timeticks) {
    on_complete_start_ = timeticks;
  }

  void set_on_complete_end(base::TimeTicks timeticks) {
    on_complete_end_ = timeticks;
  }

  void SetThrottleNetSpeed(const int64_t bytesPerSecond);

  bool IsFakeRequest() const { return is_fake_request_; }

  void SetAppendExraParams(bool enabled) { append_extra_params_ = enabled; }

  bool IsAppendExtraParams() const { return append_extra_params_; }

  void SetTncEtag(const std::string& etag) { tnc_etag_ = etag; }

  const std::string& TncEtag() const { return tnc_etag_; }

  void set_post_task_to_network_start(base::TimeTicks timeticks) {
    post_task_to_network_start_ = timeticks;
  }

  base::TimeTicks get_post_task_to_network_start() const {
    return post_task_to_network_start_;
  }

  // Use this method to replace GetResponsCode when
  // URLRequestHttpJob may be killed by user action.
  int GetResponseCodeIfJobMaybeKilled() const { return http_code_; }

  void set_is_internal_retry_req(bool val) { is_internal_retry_req_ = val; }
  bool is_internal_retry_req() const { return is_internal_retry_req_; }
#endif

  // Sets a callback that will be invoked each time the request is about to
  // be actually sent and will receive actual request headers that are about
  // to hit the wire, including SPDY/QUIC internal headers.
  //
  // Can only be set once before the request is started.
  void SetRequestHeadersCallback(RequestHeadersCallback callback);

  // Sets a callback that will be invoked each time the response is received
  // from the remote party with the actual response headers recieved. Note this
  // is different from response_headers() getter in that in case of revalidation
  // request, the latter will return cached headers, while the callback will be
  // called with a response from the server.
  void SetResponseHeadersCallback(ResponseHeadersCallback callback);

  // Sets socket tag to be applied to all sockets used to execute this request.
  // Must be set before Start() is called.  Only currently supported for HTTP
  // and HTTPS requests on Android; UID tagging requires
  // MODIFY_NETWORK_ACCOUNTING permission.
  // NOTE(pauljensen): Setting a tag disallows sharing of sockets with requests
  // with other tags, which may adversely effect performance by prohibiting
  // connection sharing. In other words use of multiplexed sockets (e.g. HTTP/2
  // and QUIC) will only be allowed if all requests have the same socket tag.
  void set_socket_tag(const SocketTag& socket_tag);
  const SocketTag& socket_tag() const { return socket_tag_; }

  // |upgrade_if_insecure| should be set to true if this request (including
  // redirects) should be upgraded to HTTPS due to an Upgrade-Insecure-Requests
  // requirement.
  void set_upgrade_if_insecure(bool upgrade_if_insecure) {
    upgrade_if_insecure_ = upgrade_if_insecure;
  }
  bool upgrade_if_insecure() const { return upgrade_if_insecure_; }

  // By default, client certs will be sent (provided via
  // Delegate::OnCertificateRequested) when cookies are disabled
  // (LOAD_DO_NOT_SEND_COOKIES / LOAD_DO_NOT_SAVE_COOKIES). As described at
  // https://crbug.com/775438, this is not the desired behavior. When
  // |send_client_certs| is set to false, this will suppress the
  // Delegate::OnCertificateRequested callback when cookies/credentials are also
  // suppressed. This method has no effect if credentials are enabled (cookies
  // saved and sent).
  // TODO(https://crbug.com/775438): Remove this when the underlying
  // issue is fixed.
  void set_send_client_certs(bool send_client_certs) {
    send_client_certs_ = send_client_certs;
  }

  base::WeakPtr<URLRequest> GetWeakPtr();

 protected:
  // Allow the URLRequestJob class to control the is_pending() flag.
  void set_is_pending(bool value) { is_pending_ = value; }

  // Setter / getter for the status of the request. Status is represented as a
  // net::Error code. See |status_|.
  int status() const { return status_; }
  void set_status(int status);

  // Returns true if the request failed or was cancelled.
  bool failed() const;

  // Returns the error status of the request.

  // Allow the URLRequestJob to redirect this request. If non-null,
  // |removed_headers| and |modified_headers| are changes
  // applied to the request headers after updating them for the redirect.
  void Redirect(
      const RedirectInfo& redirect_info,
      const base::Optional<std::vector<std::string>>& removed_headers,
      const base::Optional<net::HttpRequestHeaders>& modified_headers);

  // Called by URLRequestJob to allow interception when a redirect occurs.
  void NotifyReceivedRedirect(const RedirectInfo& redirect_info,
                              bool* defer_redirect);

 private:
  friend class URLRequestJob;
  friend class URLRequestContext;

#if BUILDFLAG(TTNET_IMPLEMENT)
  // For request log generation.
  friend class URLRequestJSONLogVisitor;
  friend class TTCommonTools;
  friend class TTNetworkDetectManager;
  friend class TTDnsCrossSpManager;
#endif

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class URLRequestJSONLogVisitorTest;
  friend class TTNetworkDelegateTest;
  friend class TTDNSCrossSpTest;
  FRIEND_TEST_ALL_PREFIXES(TTDNSCrossSpTest, HandleRequestResult);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkDetectTest, ExceptDetect);
  FRIEND_TEST_ALL_PREFIXES(TTFrontierDetectTest, CheckDetectInterval);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest,
                           CalculateEffectiveHrtt);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest,
                           CalculateEffectiveTrtt);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, CalculateNQL);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest,
                           EffectiveHttpRttSamplingWatching);
  FRIEND_TEST_ALL_PREFIXES(URLRequestTestHTTP, ClearRedirectCookie);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest, AddDownThrottleForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           ChangeDownThrottleDuringGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           HitThrottleDenyListForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddLowLevelThrottleForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddMediumLevelThrottleForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddHighLevelThrottleForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddLowLevelThrottleForPostRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddMediumLevelThrottleForPostRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddHighLevelThrottleForPostRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddMinimumLowLevelDownThrottleForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           AddEmptyThrottleDomainListForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           RemoveAllLevelThrottlesForRunningGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           RequestNoneExistThrottleLevelForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           RequestNoneExistThrottleLevelForPostRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           SetIllegalThrottleLevelForGetRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           SetIllegalThrottleLevelForPostRequest);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           DropDownRequestForSpeedThrottleFeatureII);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           DropUpRequestForSpeedThrottleFeatureII);
  FRIEND_TEST_ALL_PREFIXES(ThrottleMonitorTest,
                           ChangeDownThrottleForLowLevelThrottleGetRequest);
#endif
  // For testing purposes.
  // TODO(maksims): Remove this.
  friend class TestNetworkDelegate;

  // URLRequests are always created by calling URLRequestContext::CreateRequest.
  URLRequest(const GURL& url,
             RequestPriority priority,
             Delegate* delegate,
             const URLRequestContext* context,
             NetworkTrafficAnnotationTag traffic_annotation);

  // Resumes or blocks a request paused by the NetworkDelegate::OnBeforeRequest
  // handler. If |blocked| is true, the request is blocked and an error page is
  // returned indicating so. This should only be called after Start is called
  // and OnBeforeRequest returns true (signalling that the request should be
  // paused).
  void BeforeRequestComplete(int error);

  void StartJob(std::unique_ptr<URLRequestJob> job);

  // Restarting involves replacing the current job with a new one such as what
  // happens when following a HTTP redirect.
  void RestartWithJob(std::unique_ptr<URLRequestJob> job);
  void PrepareToRestart();

  // Cancels the request and set the error and ssl info for this request to the
  // passed values. Returns the error that was set.
  int DoCancel(int error, const SSLInfo& ssl_info);

  // Called by the URLRequestJob when the headers are received, before any other
  // method, to allow caching of load timing information.
  void OnHeadersComplete();

  // Notifies the network delegate that the request has been completed.
  // This does not imply a successful completion. Also a canceled request is
  // considered completed.
  void NotifyRequestCompleted();

  // Called by URLRequestJob to allow interception when the final response
  // occurs.
  void NotifyResponseStarted(int net_error);

  // These functions delegate to |delegate_|.  See URLRequest::Delegate for the
  // meaning of these functions.
  int NotifyConnected(const TransportInfo& info);
  void NotifyAuthRequired(std::unique_ptr<AuthChallengeInfo> auth_info);
  void NotifyCertificateRequested(SSLCertRequestInfo* cert_request_info);
  void NotifySSLCertificateError(int net_error,
                                 const SSLInfo& ssl_info,
                                 bool fatal);
  void NotifyReadCompleted(int bytes_read);

  // These functions delegate to the NetworkDelegate if it is not nullptr.
  // Otherwise, cookies can be used unless SetDefaultCookiePolicyToBlock() has
  // been called.
  bool CanGetCookies() const;
  bool CanSetCookie(const net::CanonicalCookie& cookie,
                    CookieOptions* options) const;
  PrivacyMode DeterminePrivacyMode() const;

  // Called just before calling a delegate that may block a request. |type|
  // should be the delegate's event type,
  // e.g. NetLogEventType::NETWORK_DELEGATE_AUTH_REQUIRED.
  void OnCallToDelegate(NetLogEventType type);
  // Called when the delegate lets a request continue.  Also called on
  // cancellation.
  void OnCallToDelegateComplete();

#if BUILDFLAG(TTNET_IMPLEMENT)
  URLRequest(const GURL& url, NetworkTrafficAnnotationTag traffic_annotation);

  // Called when request duration has reached |request_timeout_| limitation.
  void OnRequestTimeout(int rv);

  void SaveRequestLogToAlog();

  void TryResetExtraHeader(const RedirectInfo& redirect_info);

  void RemoveCookieHeader();

  bool IsInShareCookieList(const std::string& host) const;
#endif

  // Records the referrer policy of the given request, bucketed by
  // whether the request is same-origin or not. To save computation,
  // takes this fact as a boolean parameter rather than dynamically
  // checking.
  void RecordReferrerGranularityMetrics(bool request_is_same_origin) const;

  // Contextual information used for this request. Cannot be NULL. This contains
  // most of the dependencies which are shared between requests (disk cache,
  // cookie store, socket pool, etc.)
  const URLRequestContext* context_;

  // Tracks the time spent in various load states throughout this request.
  NetLogWithSource net_log_;

  std::unique_ptr<URLRequestJob> job_;
  std::unique_ptr<UploadDataStream> upload_data_stream_;

  std::vector<GURL> url_chain_;
  SiteForCookies site_for_cookies_;

  IsolationInfo isolation_info_;

  bool force_ignore_site_for_cookies_;
  base::Optional<url::Origin> initiator_;
  GURL delegate_redirect_url_;
  std::string method_;  // "GET", "POST", etc. Should be all uppercase.
  std::string referrer_;
  ReferrerPolicy referrer_policy_;
  RedirectInfo::FirstPartyURLPolicy first_party_url_policy_;
  HttpRequestHeaders extra_request_headers_;
  // Flags indicating the request type for the load. Expected values are LOAD_*
  // enums above.
  int load_flags_;
  // Whether the request is allowed to send credentials in general. Set by
  // caller.
  bool allow_credentials_;
  // Privacy mode for current hop. Based on |allow_credentials_|, |load_flags_|,
  // and information provided by the NetworkDelegate. Saving cookies can
  // currently be blocked independently of this field by setting the deprecated
  // LOAD_DO_NOT_SAVE_COOKIES field in |load_flags_|.
  PrivacyMode privacy_mode_;
  bool disable_secure_dns_;

  CookieAccessResultList maybe_sent_cookies_;
  CookieAndLineAccessResultList maybe_stored_cookies_;

#if BUILDFLAG(ENABLE_REPORTING)
  int reporting_upload_depth_;
#endif

  // Never access methods of the |delegate_| directly. Always use the
  // Notify... methods for this.
  Delegate* delegate_;

  // Current error status of the job, as a net::Error code. When the job is
  // busy, it is ERR_IO_PENDING. When the job is idle (either completed, or
  // awaiting a call from the URLRequestDelegate before continuing the request),
  // it is OK. If the request has been cancelled without a specific error, it is
  // ERR_ABORTED. And on failure, it's the corresponding error code for that
  // error.
  //
  // |status_| may bounce between ERR_IO_PENDING and OK as a request proceeds,
  // but once an error is encountered or the request is canceled, it will take
  // the appropriate error code and never change again. If multiple failures
  // have been encountered, this will be the first error encountered.
  int status_;

  // The HTTP response info, lazily initialized.
  HttpResponseInfo response_info_;

  // Tells us whether the job is outstanding. This is true from the time
  // Start() is called to the time we dispatch RequestComplete and indicates
  // whether the job is active.
  bool is_pending_;

  // Indicates if the request is in the process of redirecting to a new
  // location.  It is true from the time the headers complete until a
  // new request begins.
  bool is_redirecting_;

  // Number of times we're willing to redirect.  Used to guard against
  // infinite redirects.
  int redirect_limit_;

  // Cached value for use after we've orphaned the job handling the
  // first transaction in a request involving redirects.
  UploadProgress final_upload_progress_;

  // The priority level for this request.  Objects like
  // ClientSocketPool use this to determine which URLRequest to
  // allocate sockets to first.
  RequestPriority priority_;

  // If |calling_delegate_| is true, the event type of the delegate being
  // called.
  NetLogEventType delegate_event_type_;

  // True if this request is currently calling a delegate, or is blocked waiting
  // for the URL request or network delegate to resume it.
  bool calling_delegate_;

  // An optional parameter that provides additional information about what
  // |this| is currently being blocked by.
  std::string blocked_by_;
  bool use_blocked_by_as_load_param_;

  // Safe-guard to ensure that we do not send multiple "I am completed"
  // messages to network delegate.
  // TODO(battre): Remove this. http://crbug.com/89049
  bool has_notified_completion_;

  int64_t received_response_content_length_;

  base::TimeTicks creation_time_;

  // Timing information for the most recent request.  Its start times are
  // populated during Start(), and the rest are populated in OnResponseReceived.
  LoadTimingInfo load_timing_info_;

  // The proxy server used for this request, if any.
  ProxyServer proxy_server_;

  // The raw header size of the response.
  int raw_header_size_;

  const NetworkTrafficAnnotationTag traffic_annotation_;

  SocketTag socket_tag_;

  // See Set{Request|Response}HeadersCallback() above for details.
  RequestHeadersCallback request_headers_callback_;
  ResponseHeadersCallback response_headers_callback_;

  bool upgrade_if_insecure_;

  bool send_client_certs_ = true;

#if BUILDFLAG(TTNET_IMPLEMENT) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void set_response_info_for_testing(const HttpResponseInfo& info) {
    response_info_ = info;
  }
  void set_load_timing_info_for_testing(const LoadTimingInfo& info) {
    load_timing_info_ = info;
  }
  int64_t GetThrottleNetSpeedForTesting() const {
    return throttle_net_speed_;
  }

 private:
  bool start_with_offline_{false};
  bool forbid_collect_log_{false};

  NetworkChangeNotifier::ConnectionType start_net_type_{
      NetworkChangeNotifier::CONNECTION_UNKNOWN};

  int64_t format_request_log_cost_{-1};

  // The redirect info currently received.
  std::vector<RedirectInfo> redirect_chain_;
  // Flag to indicate that if the load timing info has been obtained normally.
  // If not, we need to actively try to obtain some low-level metrics.
  bool has_load_timing_info_;

  // Flag to indicate that if the response info has been obtained normally.
  // If not, we need to actively try to obtain some low-level metrics.
  bool has_response_info_;

  // Flags to indicate that the pre-processes the request has been passed,
  // so do not enter same operation again to avoid infinite loop.
  bool is_preprocessed_;

  // The request was hit the rule and dispatched by the ttnet dispatcher.
  bool is_dispatched_;

  // Return dispatch result to user.
  bool report_dispatch_info_enabled_{false};

  // The cookie header was updated after the request was hit the rule
  // and dispatched by the ttnet dispatcher.
  bool is_update_cookie_{false};

  // Flags to indicate tha if the request was start from webview.
  uint32_t request_type_flags_{net::TT_REQ_FLAG_NORMAL};

  base::TimeTicks dispatch_start_;
  base::TimeTicks dispatch_end_;

  // This value is only used to extract the tag from the header to record in the
  // log.
  std::string scene_type_;

#if BUILDFLAG(ENABLE_TIKTOK_SUPPORT)
  base::TimeTicks sandbox_start_;
  base::TimeTicks sandbox_end_;
#endif

  unsigned int dispatch_priority_;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_API_VERIFICATION)
  int ttnet_trace_id_match_{-1};
  bool is_api_source_5xx_{false};
#endif

  int64_t throttle_net_speed_;

  std::vector<DispatchActionInfo> dispatch_action_chain_;
  std::unordered_map<std::string, std::string> request_tag_;
  std::map<std::string, std::string> control_headers_;

#if defined(OS_ANDROID)
  // The time spent calling getCookie
  base::TimeTicks get_cookie_start_;
  base::TimeTicks get_cookie_end_;
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  int delay_time_{-1};
#endif

  base::TimeDelta request_delay_;

  // The request log which contains all request information that we supervised.
  std::string request_log_;

  TTNetBasicRequestInfo ttnet_basic_request_info_;

  SocketTimeoutParam socket_timeout_param_;

  // Timer to check that whether request has exceeded the duration
  // defined by |request_timeout_|.
  base::OneShotTimer request_duration_check_timer_;
  // Request duration timeout control.
  base::TimeDelta request_timeout_;

  // The time spent calling |addSecurityFactor| callback.
  base::TimeTicks security_callback_start_;
  base::TimeTicks security_callback_end_;

  base::TimeTicks before_url_request_start_;
  base::TimeTicks before_url_request_end_;

  base::TimeTicks before_start_transaction_start_;
  base::TimeTicks before_start_transaction_end_;

  base::TimeTicks on_header_recv_start_;
  base::TimeTicks on_header_recv_end_;

  base::TimeTicks on_resp_recv_start_;
  base::TimeTicks on_resp_recv_end_;

  base::TimeTicks on_complete_start_;
  base::TimeTicks on_complete_end_;

  // Fake url request for special usage by class TTCommonTools.
  bool is_fake_request_{false};

  // Append extra params for device and passport interfaces if store region is
  // enabled.
  bool append_extra_params_{false};

  // Url request dispatch config mapping to tnc etag.
  std::string tnc_etag_;

  // This is the parsed HTTP response code.
  // Store it in url request in case that http job may
  // be killed when url request was canceled by user.
  int http_code_{-1};
  int target_http_proto_type_{0};

  base::TimeTicks post_task_to_network_start_;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  int mock_response_code_{-1};
  void set_mock_respose_code_for_testing(int response_code) {
    mock_response_code_ = response_code;
  }

  bool use_mock_remote_endpoint_{false};
  IPEndPoint mock_remote_endpoint_;
  void set_mock_remote_endpoint_for_testing(IPEndPoint endpoint) {
    use_mock_remote_endpoint_ = true;
    mock_remote_endpoint_ = endpoint;
  }
#endif
  // Indicate that this request is started by internal retrying.
  bool is_internal_retry_req_{false};

#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  // Caller can add string tag to this request to indicate the requests go
  // with WiFi and Cell have relationship. If the tag is not empty,
  // it will be uploaded by request log.
  std::string mpath_request_tag_;
#endif
#endif

  THREAD_CHECKER(thread_checker_);

  base::WeakPtrFactory<URLRequest> weak_factory_{this};

  DISALLOW_COPY_AND_ASSIGN(URLRequest);
};

}  // namespace net

#endif  // NET_URL_REQUEST_URL_REQUEST_H_
