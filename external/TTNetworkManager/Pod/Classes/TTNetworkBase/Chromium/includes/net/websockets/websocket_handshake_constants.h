// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A set of common constants that are needed for the WebSocket handshake.
// In general, you should prefer using these constants to literal strings,
// except in tests.
//
// These constants cannot be used in files that are compiled on iOS, because
// this file is not compiled on iOS.

#ifndef NET_WEBSOCKETS_WEBSOCKET_HANDSHAKE_CONSTANTS_H_
#define NET_WEBSOCKETS_WEBSOCKET_HANDSHAKE_CONSTANTS_H_

#include <stddef.h>

#include "base/ttnet_implement_buildflags.h"
#include "net/base/net_export.h"

// This file plases constants inside the ::net::websockets namespace to avoid
// risk of collisions with other symbols in libnet.
namespace net {
namespace websockets {

// "HTTP/1.1"
// RFC6455 only requires HTTP/1.1 "or better" but in practice an HTTP version
// other than 1.1 should not occur in a WebSocket handshake.
extern const char kHttpProtocolVersion[];

// The Sec-WebSockey-Key challenge is 16 random bytes, base64 encoded.
extern const size_t kRawChallengeLength;

// "Sec-WebSocket-Protocol"
extern const char kSecWebSocketProtocol[];

// "Sec-WebSocket-Extensions"
extern const char kSecWebSocketExtensions[];

// "Sec-WebSocket-Key"
extern const char kSecWebSocketKey[];

// "Sec-WebSocket-Accept"
extern const char kSecWebSocketAccept[];

// "Sec-WebSocket-Version"
extern const char kSecWebSocketVersion[];

// This implementation only supports one version of the WebSocket protocol,
// "13", as specified in RFC6455. If support for multiple versions is added in
// future, it will probably no longer be worth having a constant for this.
extern const char kSupportedVersion[];

// "Upgrade"
extern const char kUpgrade[];

// "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" as defined in section 4.1 of
// RFC6455.
extern const char NET_EXPORT kWebSocketGuid[];

// "websocket", as used in the "Upgrade:" header. This is always lowercase
// (except in obsolete versions of the protocol).
extern const char kWebSocketLowercase[];

#if BUILDFLAG(TTNET_IMPLEMENT)
// add "x-support-ack:1" header if connection mode is frontier.
extern const char kSupportAck[];
#endif

}  // namespace websockets
}  // namespace net

#endif  // NET_WEBSOCKETS_WEBSOCKET_HANDSHAKE_CONSTANTS_H_
