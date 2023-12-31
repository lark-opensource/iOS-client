// Copyright (c) 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_NG_CLIENT_SERVICE_ID_REGISTRY_H_
#define CANVAS_GPU_COMMAND_BUFFER_NG_CLIENT_SERVICE_ID_REGISTRY_H_

#include <string>
#include <vector>

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace command_buffer {

class ClientServiceIdRegistry {
 public:
  explicit ClientServiceIdRegistry(std::string name) : name_(std::move(name)) {}

  ~ClientServiceIdRegistry() = default;

  uint32_t GetServiceId(uint32_t client_id) {
    for (auto &pair : client_service_id_map_) {
      if (pair.first == client_id) {
        return pair.second;
      }
    }
    return 0;
  }

  uint32_t GetClientId(uint32_t service_id) {
    for (auto &pair : client_service_id_map_) {
      if (pair.second == service_id) {
        return pair.first;
      }
    }
    return 0;
  }

  void Register(uint32_t client_id, uint32_t service_id) {
    KRYPTON_LOGV("Register ")
        << name_ << " client_id " << client_id << ", service_id " << service_id;
    client_service_id_map_.emplace_back(std::make_pair(client_id, service_id));
  }

  void Unregister(uint32_t client_id) {
    KRYPTON_LOGV("Unregister ") << name_ << " client_id " << client_id;
    for (auto it = client_service_id_map_.begin();
         it != client_service_id_map_.end(); ++it) {
      if (it->first == client_id) {
        client_service_id_map_.erase(it);
        break;
      }
    }
  }

 private:
  std::string name_;
  std::vector<std::pair<uint32_t, uint32_t>> client_service_id_map_;
};

}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_NG_CLIENT_SERVICE_ID_REGISTRY_H_
