// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_VIEW_H_
#define CANVAS_CANVAS_VIEW_H_

#include <memory>

#include "canvas/surface/surface.h"
#include "canvas_app.h"
#include "glue/canvas_runtime.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {
class Surface;
class Raster;
class CanvasElement;

constexpr uint8_t MAX_TOUCHES = 5;

struct CanvasTouchEvent {
  enum Action : uint8_t {
    TouchStart = 0,
    TouchEnd = 1,
    TouchMove = 2,
    TouchCancel = 3,
    PointerDown = 5,
    PointerUp = 6
  };

  struct {
    Action action;
    uint8_t length;
    uint8_t index;
  };
  int32_t canvas_x;
  int32_t canvas_y;
  // The number of pointers of data contained in
  // canvas surface touch event. Set the maximum number
  // of pointers to 5 in the java side;
  struct TouchItem {
    int32_t id;
    float x, y, rawX, rawY;
  } touchList[MAX_TOUCHES];
};

class CanvasView : public std::enable_shared_from_this<CanvasView> {
 public:
  CanvasView(std::string, std::shared_ptr<shell::LynxActor<CanvasRuntime>>,
             std::weak_ptr<CanvasApp> weak_canvas_app);
  virtual ~CanvasView();

  const std::string id() const { return id_; }

  // surface
  void OnSurfaceCreated(std::unique_ptr<Surface> surface, int32_t width,
                        int32_t height);
  void OnSurfaceChanged(int32_t width, int32_t height);
  void OnSurfaceDestroyed();
  // view
  void OnTouch(const CanvasTouchEvent* event);
  void OnLayoutUpdate(int32_t left, int32_t right, int32_t top, int32_t bottom,
                      int32_t width, int32_t height);
  void OnCanvasViewCreated(const std::string& id, int32_t width,
                           int32_t height);
  void OnCanvasViewDestroyed();
  void OnCanvasViewNeedRedraw();

 private:
  uintptr_t key_;
  std::string id_;
  std::unique_ptr<Surface> surface_;
  uintptr_t surface_ptr_;
  std::weak_ptr<CanvasApp> weak_canvas_app_;
  std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_VIEW_H_
