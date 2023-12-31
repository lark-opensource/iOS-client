// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_SURFACE_SURFACE_H_
#define CANVAS_SURFACE_SURFACE_H_

#include <cstddef>

namespace lynx {
namespace canvas {
class PlatformEnv;

class Surface {
 public:
  Surface() = default;
  virtual ~Surface() = default;
  //  virtual std::unique_ptr<SurfaceFrame> BeginFrame(const SkSize& size) = 0;
  //  virtual void EndFrame() = 0;
  virtual void Init() = 0;
  virtual bool Resize(int32_t width, int32_t height) { return false; };
  virtual int32_t Width() const = 0;
  virtual int32_t Height() const = 0;
  virtual void Flush() = 0;

  virtual bool IsGPUBacked() const { return false; };

  virtual bool Valid() const = 0;

  virtual bool NeedFlipY() const { return false; }

 private:
  // disallow copy&assign
  Surface(const Surface &) = delete;
  Surface &operator==(const Surface &) = delete;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_SURFACE_SURFACE_H_
