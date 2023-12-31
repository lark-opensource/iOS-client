// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_CONTEXT_H_
#define CANVAS_GPU_GL_CONTEXT_H_

#include <memory>

#include "base/base_export.h"
#include "canvas/gpu/gl_surface.h"

namespace lynx {
namespace canvas {

class GLContext {
 public:
  /// TODO by linyiyi
  static void MakeSureRealContextCreated();
  BASE_EXPORT static std::unique_ptr<GLContext> CreateReal();
  BASE_EXPORT static std::unique_ptr<GLContext> CreateVirtual();

  BASE_EXPORT static GLContext* GetCurrent();

  GLContext() = default;
  virtual ~GLContext() = default;
  virtual void Init() {}

  virtual bool MakeCurrent(GLSurface* gl_surface) = 0;
  virtual bool IsCurrent(GLSurface* gl_surface) = 0;
  virtual void ClearCurrent() = 0;

  virtual bool IsRealContext() const { return false; }

  void Ref() { ref_count_++; }

  void UnRef() {
    ref_count_--;
#ifdef OS_IOS
    if (ref_count_ <= 0) {
      ClearCurrent();
      delete this;
    }
#endif
  }

 protected:
  static void SetCurrent(GLContext* gl_context, GLSurface* gl_surface);

 private:
  int ref_count_{0};
};

GLContext** ThreadLocalRealContextPtr();

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_CONTEXT_H_
