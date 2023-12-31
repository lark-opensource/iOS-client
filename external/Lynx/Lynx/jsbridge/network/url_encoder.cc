// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/network/url_encoder.h"

#include <list>
#include <utility>

#include "base/string/string_utils.h"

namespace lynx {
namespace piper {
namespace network {

namespace {

// Make query pairs in a way conforming to TTNet's extension,
// so that nested array/list will be expended following the rules
// described below, an exemple can be:
//
// JS Object as Input:
// {"dict"={"list"=["l1","l2","l3"]}, "key"="val"}
//
// Expended pairs before percent encoding as Output:
// [
//   dict[list][] : l1,
//   dict[list][] : l2,
//   dict[list][] : l3,
//   key : val,
// ]
//
std::list<std::pair<std::string, std::string>> QueryStringPairsFromKeyAndVal(
    Runtime* rt, const std::optional<std::string>& key,
    const piper::Value& value) {
  // if value is not a object, treat it like a string
  if (!value.isObject()) {
    auto value_str = value.toString(*rt);
    if (value_str) {
      return {{key.value_or(""), value_str->utf8(*rt)}};
    } else {
      return {{key.value_or(""), ""}};
    }
  }

  std::list<std::pair<std::string, std::string>> pairs;

  auto object = value.getObject(*rt);
  if (object.isArray(*rt)) {
    // if value is an array, append `[]` at the end of the key
    // and recursivley travarse the rest of the value
    auto props_array = object.getArray(*rt);
    for (int i = 0; i < props_array.size(*rt); i++) {
      auto prop_opt = props_array.getValueAtIndex(*rt, i);
      if (prop_opt) {
        auto pair = QueryStringPairsFromKeyAndVal(rt, *key + "[]", *prop_opt);
        pairs.splice(pairs.end(), pair);
      }
    }
  } else {
    // if value is an object, append `[field_name]` at the end of the key
    // and recursivley travarse the rest of the value
    auto props_keys_opt = object.getPropertyNames(*rt);
    if (!props_keys_opt) {
      return {};
    }
    for (int i = 0; i < props_keys_opt->size(*rt); i++) {
      auto props_key_opt = props_keys_opt->getValueAtIndex(*rt, i);
      if (!props_key_opt || !props_key_opt->isString()) {
        continue;
      }
      piper::String props_key = props_key_opt->getString(*rt);
      std::string props_key_str = props_key.utf8(*rt);
      auto inner_value = object.getProperty(*rt, props_key);
      if (inner_value) {
        const auto& current_key =
            key ? *key + "[" + props_key_str + "]" : props_key_str;
        auto pair =
            QueryStringPairsFromKeyAndVal(rt, current_key, *inner_value);
        pairs.splice(pairs.end(), pair);
      }
    }
  }
  return pairs;
}

// Percent decode using `decodeURIComponent`
// Input: percent encoded string
// Output: utf8 string wrapped in JS Value
// Exemple:
//  before:  éå abc
//  after:   %C3%A9%C3%A5%20abc
std::optional<piper::Value> PercentDecode(Runtime* rt,
                                          const std::string& input) {
  auto input_copy(input);
  // defined by standard, space/plus need to be replaced by %20
  base::ReplaceAll(input_copy, "+", "%20");
  base::ReplaceAll(input_copy, " ", "%20");
  Scope scope(*rt);

  // other cases, like non-ASCII characters, are realized by
  // `decodeURIComponent` which is implemented by JS engine
  piper::Object global = rt->global();
  auto func_decode = global.getPropertyAsFunction(*rt, "decodeURIComponent");
  if (!func_decode) {
    rt->reportJSIException(JSINativeException(
        "url_encoder error: get decodeURIComponent func fail."));
    return {};
  }

  piper::Value bodyValue(
      piper::String::createFromUtf8(*rt, std::move(input_copy)));
  const Value args[1] = {std::move(bodyValue)};
  size_t count = 1;
  auto decoded_value = func_decode->call(*rt, args, count);
  if (!decoded_value || !decoded_value->isString()) {
    rt->reportJSIException(
        JSINativeException("url_encoder error: decodeURIComponent fail."));
    return {};
  }

  return decoded_value;
}

// Percent encode using `encodeURIComponent`
// Input: utf8 string
// Output: percent encode string
// Exemple:
//  before:  %C3%A9%C3%A5%20abc
//  after:   éå abc
std::string PercentEncode(Runtime* rt, const std::string& input) {
  std::string encoded;
  Scope scope(*rt);

  // normal cases, like non-ASCII characters, are realized by
  // `encodeURIComponent` implemented by JS engine
  piper::Object global = rt->global();
  auto func_encode = global.getPropertyAsFunction(*rt, "encodeURIComponent");
  if (!func_encode) {
    rt->reportJSIException(JSINativeException(
        "url_encoder error: get encodeURIComponent func fail."));
    return "";
  }

  piper::Value bodyValue(piper::String::createFromUtf8(*rt, input));
  const Value args[1] = {std::move(bodyValue)};
  size_t count = 1;
  auto encoded_value = func_encode->call(*rt, args, count);
  if (!encoded_value) {
    rt->reportJSIException(
        JSINativeException("url_encoder error: encodeURIComponent fail."));
    return "";
  }
  encoded = encoded_value->getString(*rt).utf8(*rt);

  // Some extra characters need to be replaced
  base::ReplaceAll(encoded, "!", "%21");
  base::ReplaceAll(encoded, "'", "%27");
  base::ReplaceAll(encoded, "(", "%28");
  base::ReplaceAll(encoded, ")", "%29");
  base::ReplaceAll(encoded, "~", "%7E");
  base::ReplaceAll(encoded, "%20", "+");
  base::ReplaceAll(encoded, "%00", std::string(1, '\0'));
  return encoded;
}

// decode the key-value pair, and put them into target object
void BuildObject(Runtime* rt, piper::Object& object, const std::string& pair) {
  if (pair.length() == 0) {
    // empty string
    return;
  }
  size_t pos_equal_sign = pair.find('=');
  if (pos_equal_sign == std::string::npos) {
    // no `=` sign
    const auto& key = PercentDecode(rt, pair);
    if (key) {
      object.setProperty(*rt, key->getString(*rt), "");
    }
    return;
  }
  const auto& key_string = pair.substr(0, pos_equal_sign);
  const auto& val_string = pair.substr(pos_equal_sign + 1);
  const auto& key = PercentDecode(rt, key_string);
  const auto& val = PercentDecode(rt, val_string);
  if (key && val) {
    // key=val
    object.setProperty(*rt, key->getString(*rt), *val);
  }
}

}  // namespace

// Serialize request body in `application/x-www-form-urlencoded` content-type
std::string UrlEncode(Runtime* rt, const piper::Value& body) {
  if (body.getObject(*rt).isArray(*rt)) {
    rt->reportJSIException(JSINativeException(
        "url_encoder error: try to url encode an array, not supported"));
    return "";
  }

  const auto& pairs = QueryStringPairsFromKeyAndVal(rt, {}, body);
  std::string encoded;
  for (const auto& pair : pairs) {
    encoded += PercentEncode(rt, pair.first) + "=" +
               PercentEncode(rt, pair.second) + "&";
  }

  if (encoded.length() > 0 && encoded.back() == '&') {
    return encoded.substr(0, encoded.length() - 1);
  } else {
    return encoded;
  }
}

// Deserialize response body in `application/x-www-form-urlencoded` content-type
std::optional<piper::Value> UrlDecode(Runtime* rt,
                                      const std::string& body_string) {
  piper::Object object = piper::Object(*rt);
  const char delimiter = '&';

  // find the first pair of key-value, if no '&' found
  size_t start = 0;
  size_t end = body_string.find(delimiter);
  while (end != std::string::npos) {
    const auto& pair = body_string.substr(start, end - start);

    // decode the key-value pair, and put into target object
    BuildObject(rt, object, pair);

    // find next pair of key-value
    start = end + 1;
    end = body_string.find(delimiter, start);
  }

  // take care of the rest of the body string
  const auto& rest = body_string.substr(start);
  if (rest.length()) {
    BuildObject(rt, object, rest);
  }

  return object;
}

}  // namespace network
}  // namespace piper
}  // namespace lynx
