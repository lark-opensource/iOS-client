// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file intentionally does not have header guards, it's included
// inside a macro to generate values. The following line silences a
// presubmit warning that would otherwise be triggered by this:
// no-include-guard-because-multiply-included
// NOLINT(build/header_guard)

// This is the list of load flags and their values. For the enum values,
// include the file "net/base/load_flags.h".
//
// Here we define the values using a macro LOAD_FLAG, so it can be
// expanded differently in some places (for example, to automatically
// map a load flag value to its symbolic name).

LOAD_FLAG(NORMAL, 0)

// This is "normal reload", meaning an if-none-match/if-modified-since query.
// All other caches are used as normal.
LOAD_FLAG(VALIDATE_CACHE, 1 << 0)

// This is "shift-reload", meaning a "pragma: no-cache" end-to-end fetch. All
// other caches are used as normal.
LOAD_FLAG(BYPASS_CACHE, 1 << 1)

// This is a back/forward style navigation where the cached content should
// be preferred over any protocol specific cache validation.
LOAD_FLAG(SKIP_CACHE_VALIDATION, 1 << 2)

// This is a navigation that will fail if it cannot serve the requested
// resource from the cache (or some equivalent local store).
LOAD_FLAG(ONLY_FROM_CACHE, 1 << 3)

// This is a navigation that will not use the cache at all. It does not
// impact the HTTP request headers. All other caches are used as normal.
LOAD_FLAG(DISABLE_CACHE, 1 << 4)

// If present, causes dependent network fetches (AIA, CRLs, OCSP) to be
// skipped on secure connections.
LOAD_FLAG(DISABLE_CERT_NETWORK_FETCHES, 1 << 5)

// This load will not make any changes to cookies, including storing new
// cookies or updating existing ones.
// Deprecated. Use URLRequest::set_allow_credentials instead. See
// https://crbug.com/799935.
LOAD_FLAG(DO_NOT_SAVE_COOKIES, 1 << 6)

// Do not resolve proxies. This override is used when downloading PAC files
// to avoid having a circular dependency.
LOAD_FLAG(BYPASS_PROXY, 1 << 7)

// DO NOT USE THIS FLAG
// The network stack should not have frame level knowledge.  Any pre-connect
// or pre-resolution requiring that knowledge should be done from the
// stack embedder.
// Indicate that this is a top level frame, so that we don't assume it is a
// subresource and speculatively pre-connect or pre-resolve when a referring
// page is loaded.
LOAD_FLAG(MAIN_FRAME_DEPRECATED, 1 << 8)

// Indicates that this load was motivated by the rel=prefetch feature,
// and is (in theory) not intended for the current frame.
LOAD_FLAG(PREFETCH, 1 << 9)

// Indicates that this load could cause deadlock if it has to wait for another
// request. Overrides socket limits. Must always be used with MAXIMUM_PRIORITY.
LOAD_FLAG(IGNORE_LIMITS, 1 << 10)

// Indicates that the username:password portion of the URL should not
// be honored, but that other forms of authority may be used.
LOAD_FLAG(DO_NOT_USE_EMBEDDED_IDENTITY, 1 << 11)

// Indicates that this request is not to be migrated to a cellular network when
// QUIC connection migration is enabled.
LOAD_FLAG(DISABLE_CONNECTION_MIGRATION_TO_CELLULAR, 1 << 12)

// Indicates that the cache should not check that the request matches the
// response's vary header.
LOAD_FLAG(SKIP_VARY_CHECK, 1 << 13)

// The creator of this URLRequest wishes to receive stale responses when allowed
// by the "Cache-Control: stale-while-revalidate" directive and is able to issue
// an async revalidation to update the cache. If the callee needs to revalidate
// the resource |async_revalidation_requested| attribute will be set on the
// associated HttpResponseInfo. If indicated the callee should revalidate the
// resource by issuing a new request without this flag set. If the revalidation
// does not complete in 60 seconds, the cache treat the stale resource as
// invalid, as it did not specify stale-while-revalidate.
LOAD_FLAG(SUPPORT_ASYNC_REVALIDATION, 1 << 14)

// Indicates that a prefetch request's cached response should be restricted in
// in terms of reuse. The cached response can only be reused by requests with
// the LOAD_CAN_USE_RESTRICTED_PREFETCH load flag.
LOAD_FLAG(RESTRICTED_PREFETCH, 1 << 15)

// This flag must be set on requests that are allowed to reuse cache entries
// that are marked as RESTRICTED_PREFETCH. Requests without this flag cannot
// reuse restricted prefetch responses in the cache. Restricted response reuse
// is considered privileged, and therefore this flag must only be set from a
// trusted process.
LOAD_FLAG(CAN_USE_RESTRICTED_PREFETCH, 1 << 16)

#if BUILDFLAG(TTNET_IMPLEMENT)
// Indicates that this request is not to use alternative job even if the
// alternative job is exist.
// This flag is only used during QUIC/TCP performance comparison testing.
LOAD_FLAG(SKIP_ALTER_JOB, 1 << 20)

// Indicates that this request is not to use main job until the alternative
// job failed.
// This flag is only used during QUIC/TCP performance comparison testing.
LOAD_FLAG(SKIP_MAIN_JOB, 1 << 21)

// Indicates that this request will skip network delegate.
// This flag will be set when http reqeust header exists
// "x-ttnet-bypass-delegate: 1". Flag will be unset when added 
// "x-ttnet-bypass-delegate: 0" to http request header.
LOAD_FLAG(BYPASS_DELEGATE, 1 << 22)

// This flag is used to optimize the last read for native interface.
LOAD_FLAG(OPTIMAL_LAST_READ, 1 << 23)

// Set Force Disable Privacy Mode
LOAD_FLAG(FORCE_PRIVACY_MODE_DISABLED, 1 << 24)

// Set this bit to force using the network specified by
// |USE_ALTERNATIVE_NETWORK| bit. If |USE_ALTERNATIVE_NETWORK| is not set,
// default network will be forced using by this request. If
// |USE_ALTERNATIVE_NETWORK| is set, alternative network will be forced using.
// If this bit is not forced set, request will try to use Default or Alternative
// network based on |USE_ALTERNATIVE_NETWORK| bit value. If alternative network
// is used and is unavailable, request will try default network instead.
LOAD_FLAG(FORCE_USE_SPECIFIED_NETWORK, 1 << 28)

// Set this bit to use alternative network to send this request. If
// |FORCE_USE_SPECIFIED_NETWORK| is also set, it will be forced to use
// alternative network, and return -187 error code when the alternative
// network is unavailable, which means that WiFi and Cell are not both on.
LOAD_FLAG(USE_ALTERNATIVE_NETWORK, 1 << 29)

// Request is caused by net error retry.
LOAD_FLAG(INTERNAL_RETRY_REQ, 1 << 30)

// Force use new created socket
LOAD_FLAG(FORCE_NEW_SOCKET, 1 << 31)
#endif
