// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_GL_RESOURCE_MANAGER_H_
#define CANVAS_GPU_COMMAND_BUFFER_GL_RESOURCE_MANAGER_H_

#include <vector>

#include "canvas/base/macros.h"

namespace lynx {
namespace canvas {
class GLResourceManager {
 public:
  GLResourceManager(CommandRecorder *recorder) {}

  void CreateNewPair(GLuint client_id, GLuint service_id) {
    client_service_id_mapping_.resize(client_id + 1);
    client_service_id_mapping_[client_id] = service_id;
  }

  void DeletePair(GLuint client_id) {
    DCHECK(client_service_id_mapping_.size() > client_id);
    client_service_id_mapping_[client_id] = 0;
  }

  GLuint GetServiceId(GLuint client_id) {
    DCHECK(client_service_id_mapping_.size() > client_id);
    return client_service_id_mapping_[client_id];
  }

  GLuint GetClientId(GLuint service_id) {
    DCHECK(client_service_id_mapping_.size());

    for (auto i = 0; i < client_service_id_mapping_.size(); i++) {
      if (service_id == client_service_id_mapping_[i]) {
        return i;
      }
    }
    return 0;
  }

 private:
  std::vector<GLuint> client_service_id_mapping_;

  LYNX_CANVAS_DISALLOW_ASSIGN_COPY(GLResourceManager);
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_GL_RESOURCE_MANAGER_H_
