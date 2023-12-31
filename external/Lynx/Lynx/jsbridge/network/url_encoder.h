// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NETWORK_URL_ENCODER_H_
#define LYNX_JSBRIDGE_NETWORK_URL_ENCODER_H_

#include <string>

#include "jsbridge/module/lynx_module.h"

namespace lynx {
namespace piper {
namespace network {

// Serialize request body in `application/x-www-form-urlencoded` content-type
// Input: JS Object
// Output: urlencoded string
// Exemple:
//    {
//     "a" : 123
//     "b" : "abc"
//    }
//
// encoded to:
//    a=123&b=abc
//
std::string UrlEncode(Runtime* rt, const piper::Value& body);

// Deserialize response body in `application/x-www-form-urlencoded` content-type
// Input: urlencoded string
// Output: JS Object
// Exemple:
//    a=123&b=abc
//
// decoded to:
//    {
//     "a" : 123
//     "b" : "abc"
//    }
std::optional<piper::Value> UrlDecode(Runtime* rt,
                                      const std::string& body_string);

}  // namespace network
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NETWORK_URL_ENCODER_H_
