// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxCanvasView.h"
#import "LynxComponentRegistry.h"
#import "LynxLog.h"
#import "LynxUICanvas.h"
#include "canvas/canvas_view.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/ios/gl_surface_ios.h"
#include "shell/lynx_shell.h"

static const NSInteger defaultCanvasWidth = 300;
static const NSInteger defaultCanvasHeight = 150;

using namespace lynx;
using namespace canvas;

@implementation LynxCanvasView {
  std::unique_ptr<lynx::canvas::CanvasView> native_canvas_view_;
  NSString *_id;
  BOOL _initialized;
  NSInteger _width;
  NSInteger _height;
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)init {
  if (self = [super init]) {
    _width = defaultCanvasWidth;
    _height = defaultCanvasHeight;
  }
  return self;
}

- (void)dealloc {
  if (native_canvas_view_) {
    native_canvas_view_->OnSurfaceDestroyed();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  [self tryToInitCanvas];
}

- (void)appDidBecomeActive:(UIApplication *)application {
  LLogInfo(@"KryptonLynxCanvasView receive appDidBecomeActive notification.");
  if (native_canvas_view_) {
    native_canvas_view_->OnCanvasViewNeedRedraw();
  }
}

- (void)setId:(NSString *)id {
  _id = id;
  [self tryToInitCanvas];
}

- (void)onLayoutUpdate:(NSInteger)left
                 right:(NSInteger)right
                   top:(NSInteger)top
                bottom:(NSInteger)bottom
                 width:(NSInteger)width
                height:(NSInteger)height {
  if (native_canvas_view_) {
    CGFloat scale = [UIScreen mainScreen].scale;
    native_canvas_view_->OnSurfaceChanged(width * scale, height * scale);
    native_canvas_view_->OnLayoutUpdate(static_cast<int>(left), static_cast<int>(right),
                                        static_cast<int>(top), static_cast<int>(bottom),
                                        static_cast<int>(width), static_cast<int>(height));
  }
}

- (void)tryToInitCanvas {
  if (!_initialized && _id) {
    [self InitCanvasInternal];
  }
}

- (void)freeCanvasMemory {
  if (native_canvas_view_) {
    _initialized = NO;
    native_canvas_view_->OnSurfaceDestroyed();
    native_canvas_view_ = nullptr;
  }
}

- (void)restoreCanvasView {
  [self tryToInitCanvas];
  [self frameDidChange];
}

- (void)InitCanvasInternal {
  _initialized = YES;
  [self createNativeCanvasView];
}

- (void)createNativeCanvasView {
  auto *shell = reinterpret_cast<lynx::shell::LynxShell *>([[_ui context] shellPtr]);
  if (!shell) {
    return;
  }

  auto manager = shell->GetCanvasManager().lock();
  if (!manager) {
    return;
  }

  auto canvasAppHandler = manager->GetCanvasAppHandler();
  if (!canvasAppHandler) {
    return;
  }

  auto app = lynx::canvas::CanvasAppIOS::CanvasAppFromHandler(canvasAppHandler);
  if (!app) {
    return;
  }

  if (!native_canvas_view_) {
    native_canvas_view_ =
        std::make_unique<lynx::canvas::CanvasView>([_id UTF8String], app -> runtime_actor(), app);
  }

  CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
  layer.opaque = NO;
  layer.contentsScale = [UIScreen mainScreen].scale;
  auto width = layer.bounds.size.width * layer.contentsScale;
  auto height = layer.bounds.size.height * layer.contentsScale;
  auto gl_surface = std::make_unique<GLSurfaceIOS>(reinterpret_cast<CAEAGLLayer *>(layer));
  native_canvas_view_->OnCanvasViewCreated([_id UTF8String], self.ui.frame.size.width,
                                           self.ui.frame.size.height);
  native_canvas_view_->OnSurfaceCreated(std::move(gl_surface), width, height);

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)frameDidChange {
  [self onLayoutUpdate:self.ui.frame.origin.x
                 right:self.ui.frame.origin.x + self.ui.frame.size.width
                   top:self.ui.frame.origin.y
                bottom:self.ui.frame.origin.y + self.ui.frame.size.height
                 width:self.ui.frame.size.width
                height:self.ui.frame.size.height];
}

- (bool)dispatchTouch:(NSString *const)touchType
              touches:(NSSet<UITouch *> *)touches
            withEvent:(UIEvent *)event {
  if (event.allTouches.count > MAX_TOUCHES) {
    return NO;
  }

  if ([touchType isEqualToString:LynxEventTouchStart]) {
    NSMutableArray *touchArray = [[NSMutableArray alloc] init];
    uint32_t i = 0;
    for (UITouch *touch in event.allTouches) {
      if ([touches member:touch]) continue;
      [touchArray addObject:touch];
      i++;
    }

    for (UITouch *touch in touches) {
      [touchArray addObject:touch];
      i++;
      [self sendTouch:touchArray type:CanvasTouchEvent::TouchStart index:i - 1 length:i];
      if (i == MAX_TOUCHES) {
        break;
      }
    }
  } else if ([touchType isEqualToString:LynxEventTouchMove]) {
    NSMutableArray *touchArray = [[NSMutableArray alloc] init];
    uint32_t i = 0;
    for (UITouch *touch in event.allTouches) {
      [touchArray addObject:touch];
      i++;
    }
    [self sendTouch:touchArray type:CanvasTouchEvent::TouchMove index:0 length:i];
  } else if ([touchType isEqualToString:LynxEventTouchEnd]) {
    NSMutableArray *touchArray = [[NSMutableArray alloc] init];
    uint32_t i = 0;
    for (UITouch *touch in event.allTouches) {
      if ([touches member:touch]) continue;
      [touchArray addObject:touch];
      i++;
    }
    uint32_t start = i;
    for (UITouch *touch in touches) {
      [touchArray addObject:touch];
      i++;
      if (i == MAX_TOUCHES) {
        break;
      }
    }
    while (i > start) {
      [self sendTouch:touchArray type:CanvasTouchEvent::TouchEnd index:i - 1 length:i];
      i--;
    }
  } else if ([touchType isEqualToString:LynxEventTouchCancel]) {
    NSMutableArray *touchArray = [[NSMutableArray alloc] init];
    uint32_t i = 0;
    for (UITouch *touch in event.allTouches) {
      if ([touches member:touch]) continue;
      [touchArray addObject:touch];
      i++;
    }
    uint32_t start = i;
    for (UITouch *touch in touches) {
      [touchArray addObject:touch];
      i++;
      if (i == MAX_TOUCHES) {
        break;
      }
    }
    while (i > start) {
      [self sendTouch:touchArray type:CanvasTouchEvent::TouchCancel index:i - 1 length:i];
      i--;
    }
  }

  return NO;
}

- (void)sendTouch:(NSMutableArray *)touchList
             type:(CanvasTouchEvent::Action)type
            index:(NSInteger)index
           length:(NSInteger)length {
  if (!native_canvas_view_) {
    return;
  }

  CanvasTouchEvent event;
  event.action = type;
  event.index = index;
  event.length = length;

  CGRect clientRect = [self.ui getBoundingClientRect];
  event.canvas_x = clientRect.origin.x;
  event.canvas_y = clientRect.origin.y;

  for (NSUInteger i = 0; i < length; i++) {
    UITouch *touch = touchList[i];
    CGPoint pos = [touch locationInView:self];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-objc-pointer-introspection"
    int32_t touch_id = (reinterpret_cast<intptr_t>(touch) & 0x7fffffff) ^ 0x7eadbeef;
#pragma clang diagnostic pop
    event.touchList[i].id = touch_id;
    event.touchList[i].x = pos.x;
    event.touchList[i].y = pos.y;
    CGPoint raw = [touch locationInView:nil];
    event.touchList[i].rawX = raw.x;
    event.touchList[i].rawY = raw.y;
  }
  native_canvas_view_->OnTouch(&event);
}

@end
