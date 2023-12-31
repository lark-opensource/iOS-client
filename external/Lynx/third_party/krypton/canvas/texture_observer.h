// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_TEXTURE_OBSERVER_H_
#define CANVAS_TEXTURE_OBSERVER_H_

namespace lynx {
namespace canvas {
class TextureObserver {
 public:
  virtual void OnTextureCreated(unsigned int texture_id) {}
  virtual void OnUpdateTexture() {}
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_TEXTURE_OBSERVER_H_
