// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxFrameViewTrace.h"
#include <mach/mach_time.h>
#include <chrono>
#import "LynxFrameTraceService.h"
#if OS_IOS
#import <Lynx/LynxTraceEvent.h>
#elif OS_OSX
#import <LynxMacOS/LynxTraceEvent.h>
#endif

#if LYNX_ENABLE_TRACING
#import "tracing/platform/frameview_trace_plugin_darwin.h"
#endif

@implementation LynxFrameViewTrace {
  // compress quality of a picture, default is 70
  int _defaultScreenshotQuality;
  // Maximum number of pixels of a picture, default is 256000 pixels
  int _maxScreenshotAreaSize;
#if LYNX_ENABLE_TRACING
  std::unique_ptr<lynx::base::tracing::TracePlugin> _frameview_trace_plugin;
#endif
}

+ (instancetype)shareInstance {
  static LynxFrameViewTrace* instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)init {
  if (self = [super init]) {
    _defaultScreenshotQuality = 70;
    _maxScreenshotAreaSize = 256000;
    self.delegate = self;
#if LYNX_ENABLE_TRACING
    _frameview_trace_plugin = std::make_unique<lynx::base::tracing::FrameViewTracePluginDarwin>();
#endif
  }
  return self;
}

- (BOOL)isEnabled {
  return [LynxTraceEvent categoryEnabled:@"disabled-by-default-devtools.screenshot"];
}

#if OS_IOS
- (NSString*)takeSnapshot:(UIView*)view {
  float screen_factor = [UIScreen mainScreen].scale;
  float origin_width = view.frame.size.width * screen_factor;
  float origin_height = view.frame.size.height * screen_factor;
  double area = origin_width * origin_height;
  double scale = 1;
  if (area > _maxScreenshotAreaSize) {
    scale = sqrt(_maxScreenshotAreaSize / area);
  }
  UIGraphicsBeginImageContextWithOptions(
      CGSizeMake(CGRectGetWidth(view.frame), CGRectGetHeight(view.frame)), NO, 0.0);
  CGRect rect = CGRectMake(0.0, 0.0, view.frame.size.width, view.frame.size.height);
  UIWindow* window = [UIApplication sharedApplication].keyWindow;
  [[window backgroundColor] setFill];
  UIRectFill(rect);
  [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  if (image == nil) return nil;
  int scaleWidth = image.size.width * scale;
  int scaleHeight = image.size.height * scale;
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaleWidth, scaleHeight), NO, 0);
  [image drawInRect:CGRectMake(0, 0, scaleWidth, scaleHeight)];
  UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  if (scaledImage == nil) return nil;
  NSData* data = UIImageJPEGRepresentation(scaledImage, _defaultScreenshotQuality / 100.0);
  NSString* snapshot =
      [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return snapshot;
}
#elif OS_OSX
- (NSString*)takeSnapshot:(NSView*)view {
  float scaleFactor = [NSScreen mainScreen].backingScaleFactor;
  float originWidth = view.frame.size.width * scaleFactor;
  float originHeight = view.frame.size.height * scaleFactor;
  double area = originWidth * originHeight;
  double scale = 1;
  if (area > _maxScreenshotAreaSize) {
    scale = sqrt(_maxScreenshotAreaSize / area);
  }
  NSWindow* window = view.window;
  CGRect rect = view.bounds;
  rect = [view convertRect:rect toView:nil];
  rect = [window convertRectToScreen:rect];
  CGRect frame = [NSScreen mainScreen].frame;
  rect.origin.y = frame.size.height - rect.size.height - rect.origin.y;

  CGImageRef cgImage = CGWindowListCreateImage(
      rect, kCGWindowListOptionIncludingWindow, CGWindowID(window.windowNumber),
      kCGWindowImageNominalResolution | kCGWindowImageBoundsIgnoreFraming);
  NSImage* image = [[NSImage alloc] initWithCGImage:cgImage size:rect.size];

  int scaleWidth = image.size.width * scale;
  int scaleHeight = image.size.height * scale;
  NSSize size = NSMakeSize(scaleWidth, scaleHeight);
  NSImage* scaledImage = [[NSImage alloc] initWithSize:size];
  [scaledImage lockFocus];
  [image drawInRect:CGRectMake(0, 0, scaleWidth, scaleHeight)];
  NSBitmapImageRep* bits =
      [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, scaleWidth, scaleHeight)];
  [scaledImage unlockFocus];
  NSDictionary* imageProps = [NSDictionary
      dictionaryWithObject:[NSNumber numberWithFloat:_defaultScreenshotQuality / 100.0]
                    forKey:NSImageCompressionFactor];
  NSData* data = [bits representationUsingType:NSJPEGFileType properties:imageProps];
  NSString* str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

  return str;
}
#endif

- (void)onNewSnapshot:(NSString*)data {
  [[LynxFrameTraceService shareInstance] screenshot:data];
}

- (void)onFrameChanged {
  [self screenshot];
}

- (intptr_t)getFrameViewTracePlugin {
#if LYNX_ENABLE_TRACING
  return reinterpret_cast<intptr_t>(_frameview_trace_plugin.get());
#endif
  return 0;
}

@end
