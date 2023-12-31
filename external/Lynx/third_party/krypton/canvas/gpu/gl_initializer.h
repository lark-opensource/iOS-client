// Copyright (c) 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_INITIALIZER_H_
#define CANVAS_GPU_GL_INITIALIZER_H_

#include <atomic>

#include "gl_context.h"
#include "third_party/fml/task_runner.h"

namespace lynx {
namespace canvas {

class GLInitializer {
 public:
  // only called on js thread
  static GLInitializer &Instance();

  GLInitializer(const GLInitializer &) = delete;
  GLInitializer &operator=(const GLInitializer &) = delete;

  bool InitOnJSThreadBlocked(
      const fml::RefPtr<fml::TaskRunner> &gpu_task_runner);
  bool InitOnJSThreadAsync(const fml::RefPtr<fml::TaskRunner> &gpu_task_runner);

  bool Initialized() const { return initialized; }

 private:
  GLInitializer();

  bool InitImpl(const fml::RefPtr<fml::TaskRunner> &initialized_flag,
                bool sync);
  void InitOnGPU();

  std::atomic_bool initialized;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_INITIALIZER_H_
