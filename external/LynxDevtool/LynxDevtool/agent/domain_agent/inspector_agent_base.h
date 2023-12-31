// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_AGENT_BASE_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_AGENT_BASE_H_

#include <map>
#include <string>

#include "base/log/logging.h"
#include "base/ref_counted_ptr.h"
#include "third_party/jsoncpp/include/json/json.h"
#include "third_party/modp_b64/modp_b64.h"
#include "third_party/zlib/zlib.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentBase;

class InspectorAgentBase : public lynx::base::RefCountPtr<InspectorAgentBase> {
 public:
  InspectorAgentBase()
      : use_compression_(false), compression_threshold_(10240) {}
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) = 0;

  int CompressData(const std::string& tag, const std::string& data,
                   Json::Value& value, const std::string& key) {
    uLong compressed_size = data.size() * 1.1 + 12;
    std::unique_ptr<Byte[]> compressed_data =
        std::make_unique<Byte[]>(compressed_size);
    int z_result = compress(compressed_data.get(), &compressed_size,
                            reinterpret_cast<const Cr_z_Bytef*>(data.c_str()),
                            data.size());
    if (z_result == Z_OK) {
      unsigned long base64_size = modp_b64_encode_len(compressed_size);
      std::unique_ptr<char[]> base64_data =
          std::make_unique<char[]>(base64_size);
      modp_b64_encode(base64_data.get(),
                      reinterpret_cast<const char*>(compressed_data.get()),
                      compressed_size);

      LOGI("[" << tag << "] original size " << data.size()
               << ", compressed size " << compressed_size << ", base64 size "
               << base64_size);

      value["compress"] = true;
      value[key] = std::string(base64_data.get());
    }

    return z_result;
  }

 protected:
  bool use_compression_;
  int compression_threshold_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_AGENT_BASE_H_
