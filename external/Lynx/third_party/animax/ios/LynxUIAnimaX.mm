// Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxUIAnimaX.h"

#import "LynxComponentRegistry.h"
#import "LynxPropsProcessor.h"
#import "LynxUIMethodProcessor.h"
#include "animax/base/log.h"
#include "animax/bridge/animax_element.h"
#include "animax/bridge/animax_event.h"
#include "canvas/gpu/gl_surface.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/ios/gl_surface_ios.h"
#include "shell/lynx_shell.h"

@implementation LynxUIAnimaX {
  std::shared_ptr<lynx::animax::AnimaXElement> _element;
  BOOL _surfaceCreated;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("animax-view")
#else
LYNX_REGISTER_UI("animax-view")
#endif

LYNX_PROP_SETTER("src", src, NSString *) {
  if (![value isKindOfClass:[NSString class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetSrc([value UTF8String]);
}

LYNX_PROP_SETTER("src-format", srcFormat, NSString *) {
  if (![value isKindOfClass:[NSString class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetSrc([value UTF8String]);
}

LYNX_PROP_SETTER("src-polyfill", srcPolyfill, NSDictionary *) {
  if (![value isKindOfClass:[NSDictionary class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  __block std::unordered_map<std::string, std::string> polyfill;
  [value
      enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && [key isKindOfClass:[NSString class]]) {
          polyfill[std::string([key UTF8String])] = std::string([obj UTF8String]);
        }
      }];
  element->SetSrcPolyfill(polyfill);
}

LYNX_PROP_SETTER("json", json, NSString *) {
  if (![value isKindOfClass:[NSString class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetJson([value UTF8String]);
}

LYNX_PROP_SETTER("loop", loop, BOOL) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetLoop(value);
}

LYNX_PROP_SETTER("start-frame", startFrame, NSNumber *) {
  if (![value isKindOfClass:[NSNumber class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetStartFrame([value doubleValue]);
}

LYNX_PROP_SETTER("end-frame", endFrame, NSNumber *) {
  if (![value isKindOfClass:[NSNumber class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetEndFrame([value doubleValue]);
}

LYNX_PROP_SETTER("auto-reverse", autoReverse, BOOL) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetAutoReverse(value);
}

LYNX_PROP_SETTER("progress", progress, NSNumber *) {
  if (![value isKindOfClass:[NSNumber class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetProgress([value doubleValue]);
}

LYNX_PROP_SETTER("loop-count", repeatCount, NSNumber *) {
  if (![value isKindOfClass:[NSNumber class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetLoopCount([value intValue]);
}

LYNX_PROP_SETTER("objectfit", objectfit, NSString *) {
  if (![value isKindOfClass:[NSString class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  lynx::animax::AnimaXElement::ObjectFit objectFit =
      lynx::animax::AnimaXElement::ObjectFit::kCenter;
  if ([@"cover" isEqualToString:value]) {
    objectFit = lynx::animax::AnimaXElement::ObjectFit::kCover;
  } else if ([@"contain" isEqualToString:value]) {
    objectFit = lynx::animax::AnimaXElement::ObjectFit::kContain;
  }
  element->SetObjectFit(objectFit);
}

LYNX_PROP_SETTER("autoplay", autoplay, BOOL) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetAutoplay(value);
}

LYNX_PROP_SETTER("speed", speed, NSNumber *) {
  if (![value isKindOfClass:[NSNumber class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetSpeed([value doubleValue]);
}

LYNX_PROP_SETTER("fps-event-interval", interval, NSNumber *) {
  if (![value isKindOfClass:[NSNumber class]]) {
    return;
  }
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->SetFpsEventInterval([value longValue]);
}

LYNX_UI_METHOD(play) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->Play();
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

LYNX_UI_METHOD(resume) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->Resume();
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

LYNX_UI_METHOD(stop) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->Stop();
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

LYNX_UI_METHOD(pause) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  element->Pause();
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

LYNX_UI_METHOD(getDuration) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  if (callback) {
    callback(
        kUIMethodSuccess,
        @{@"data" : @(element->GetDurationMs())});
  }
}

LYNX_UI_METHOD(isAnimating) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  if (callback) {
    callback(
        kUIMethodSuccess,
        @{@"data" : @(element->IsAnimating())});
  }
}

LYNX_UI_METHOD(subscribeUpdateEvent) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  NSNumber *frame = params[@"frame"];
  if ([frame isKindOfClass:[NSNumber class]]) {
    element->SubscribeUpdateEvent([frame intValue]);
    if (callback) {
      callback(kUIMethodSuccess, nil);
    }
  } else {
    if (callback) {
      callback(kUIMethodParamInvalid, nil);
    }
  }
}

LYNX_UI_METHOD(unsubscribeUpdateEvent) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  NSNumber *frame = params[@"frame"];
  if ([frame isKindOfClass:[NSNumber class]]) {
    element->UnsubscribeUpdateEvent([frame intValue]);
    if (callback) {
      callback(kUIMethodSuccess, nil);
    }
  } else {
    if (callback) {
      callback(kUIMethodParamInvalid, nil);
    }
  }
}

LYNX_UI_METHOD(seek) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  NSNumber *frame = params[@"frame"];
  if ([frame isKindOfClass:NSNumber.class]) {
    element->Seek([frame doubleValue]);
    if (callback) {
      callback(kUIMethodSuccess, nil);
    }
  } else {
    if (callback) {
      callback(kUIMethodParamInvalid, nil);
    }
  }
}

LYNX_UI_METHOD(getCurrentFrame) {
  auto element = [self getElement];
  if (!element) {
    return;
  }
  if (callback) {
    callback(kUIMethodSuccess, @(element->GetCurrentFrame()));
  }
}

- (std::shared_ptr<lynx::animax::AnimaXElement>)getElement {
  if (!_element) {
    auto canvasApp = [self getCanvasApp];
    if (!canvasApp) {
      ANIMAX_LOGE("getElement error: canvasApp is nullptr");
      return nullptr;
    }
    using lynx::animax::AnimaXElement;
    using lynx::animax::Event;
    using lynx::animax::IEventParams;
    __weak typeof(self) weakSelf = self;
    _element = std::make_shared<AnimaXElement>(canvasApp, self.view.layer.contentsScale);
    _element->AddEventListener(
        [weakSelf](AnimaXElement *element, const Event event, IEventParams *params) {
          NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
          if (event != Event::kError) {
            dictionary[@(lynx::animax::kKeyAnimationId.c_str())] =
                [NSString stringWithCString:element->GetAnimationID().c_str()
                                   encoding:[NSString defaultCStringEncoding]];
            dictionary[@(lynx::animax::kKeyCurrent.c_str())] = @(element->GetCurrentFrame());
            dictionary[@(lynx::animax::kKeyTotal.c_str())] = @(element->GetTotalFrame());
            dictionary[@(lynx::animax::kKeyLoopIndex.c_str())] = @(element->GetLoopIndex());
          }

          if (event == Event::kError) {
            auto *error_param = static_cast<lynx::animax::ErrorParams *>(params);
            if (error_param) {
              [dictionary setObject:@(error_param->error_code_)
                             forKey:@(lynx::animax::kKeyCode.c_str())];
              [dictionary setObject:[NSString stringWithCString:error_param->error_message_.c_str()
                                                       encoding:[NSString defaultCStringEncoding]]
                             forKey:@(lynx::animax::kKeyMessage.c_str())];
            }
          } else if (event == Event::kFps) {
            auto *fps_param = static_cast<lynx::animax::FpsParams *>(params);
            if (fps_param) {
              dictionary[@(lynx::animax::kKeyMaxDropRate.c_str())] = @(fps_param->max_drop_rate_);
              dictionary[@(lynx::animax::kKeyFps.c_str())] = @(fps_param->fps_);
            }
          }

          dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf sendEvent:event params:dictionary];
          });
        });
    _element->Init();
  }
  return _element;
}

- (LynxAnimaXView *)createView {
  LynxAnimaXView *view = [[LynxAnimaXView alloc] init];
  return view;
}

- (instancetype)init {
  if (self = [super init]) {
    _surfaceCreated = NO;
  }
  return self;
}

- (void)dealloc {
  if (_element) {
    _element->Destroy();
    _element = nullptr;
  }
}

- (std::shared_ptr<lynx::canvas::CanvasApp>)getCanvasApp {
  auto shellPtr = reinterpret_cast<lynx::shell::LynxShell *>([self.context shellPtr]);
  if (!shellPtr) {
    return nullptr;
  }
  auto manager = shellPtr->GetCanvasManager().lock();
  if (!manager) {
    return nullptr;
  }
  auto canvasAppHandler = manager->GetCanvasAppHandler();
  if (!canvasAppHandler) {
    return nullptr;
  }
  return lynx::canvas::CanvasAppIOS::CanvasAppFromHandler(canvasAppHandler);
}

- (void)frameDidChange {
  [super frameDidChange];

  const CGFloat scale = self.view.layer.contentsScale;
  const CGFloat width = scale * self.view.bounds.size.width;
  const CGFloat height = scale * self.view.bounds.size.height;
  auto element = [self getElement];
  if (!element) {
    ANIMAX_LOGE("frameDidChange, but element is nullptr");
    return;
  }
  if (!_surfaceCreated) {
    CAEAGLLayer *layer = reinterpret_cast<CAEAGLLayer *>(self.view.layer);
    auto surface = std::make_unique<lynx::canvas::GLSurfaceIOS>(layer);
    element->OnSurfaceCreated(width, height, std::move(surface));
    _surfaceCreated = YES;
  } else {
    element->OnSurfaceChanged(width, height);
  }
}

- (void)sendEvent:(lynx::animax::Event)event params:(NSDictionary *)params {
  NSString *eventName = nil;
  switch (event) {
    case lynx::animax::Event::kCompletion:
      eventName = @"completion";
      break;
    case lynx::animax::Event::kStart:
      eventName = @"start";
      break;
    case lynx::animax::Event::kRepeat:
      eventName = @"repeat";
      break;
    case lynx::animax::Event::kCancel:
      eventName = @"cancel";
      break;
    case lynx::animax::Event::kReady:
      eventName = @"ready";
      break;
    case lynx::animax::Event::kUpdate:
      eventName = @"update";
      break;
    case lynx::animax::Event::kError:
      eventName = @"error";
      break;
    case lynx::animax::Event::kFps:
      eventName = @"fps";
      break;
    default:
      break;
  }

  if (![eventName length]) {
    return;
  }
  LynxCustomEvent *customEvent = [[LynxDetailEvent alloc] initWithName:eventName
                                                            targetSign:[self sign]
                                                                detail:params];
  [self.context.eventEmitter sendCustomEvent:customEvent];
}

@end
