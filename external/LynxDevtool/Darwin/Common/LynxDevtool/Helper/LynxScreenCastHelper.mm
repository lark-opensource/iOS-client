// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxScreenCastHelper.h"
#import <CoreGraphics/CoreGraphics.h>
#include <memory>
#import "LynxDevtoolFrameCapturer.h"
#import <Lynx/LynxLog.h>
#include "base/screen_metadata.h"
#if OS_IOS
#import <Lynx/LynxView.h>
#elif OS_OSX
#import <LynxMacOS/LynxView.h>
#endif

static int const kCardPreviewQuality = 80;
static int const kCardPreviewMaxWidth = 150;
static int const kCardPreviewMaxHeight = 300;

#pragma mark - LynxInspectorOwner
@interface LynxInspectorOwner ()
- (void)sendScreenCast:(NSString*)data
           andMetadata:(std::shared_ptr<lynxdev::devtool::ScreenMetadata>)metadata;
@end

#pragma mark - LynxInspectorOwnerScreenCastHelper
@interface LynxInspectorOwnerScreenCastHelper : LynxDevtoolFrameCapturer <FrameCapturerDelegate>

- (instancetype)initWithLynxView:(LynxView*)root withOwner:(LynxInspectorOwner*)owner;

- (void)attachLynxView:(nonnull LynxView*)view;

- (void)startCapture:(int)quality width:(int)max_width height:(int)max_height;
- (void)stopCapture;
- (void)onAckReceived;

@end

@implementation LynxInspectorOwnerScreenCastHelper {
  int max_height_;
  int max_width_;
  int quality_;
  BOOL enabled_;
  BOOL ack_received_;

  dispatch_queue_t _computeQueue;
  __weak LynxInspectorOwner* _owner;
  __weak LynxView* _lynxView;

  std::shared_ptr<lynxdev::devtool::ScreenMetadata> screen_metadata_;
}

- (instancetype)initWithLynxView:(LynxView*)root withOwner:(LynxInspectorOwner*)owner {
  if (self = [super init]) {
    max_width_ = 0;
    max_height_ = 0;
    quality_ = 0;
    enabled_ = NO;
    ack_received_ = NO;

    _computeQueue = dispatch_queue_create("ScreenCaster.render_queue", DISPATCH_QUEUE_SERIAL);
    _lynxView = root;
    _owner = owner;

    screen_metadata_ = std::make_shared<lynxdev::devtool::ScreenMetadata>();
    self.delegate = self;
  }
  return self;
}

- (void)attachLynxView:(nonnull LynxView*)view {
  [self attachView:view];
  _lynxView = view;
}

#if OS_IOS
- (UIColor*)getBackgroundColor {
  if (_lynxView == nil) {
    return nil;
  }
  UIView* view = _lynxView;
  auto parent_view = [view superview];
  UIColor* res = [UIColor whiteColor];
  while (parent_view &&
         (![view backgroundColor] || [[view backgroundColor] isEqual:[UIColor clearColor]])) {
    view = parent_view;
    parent_view = [view superview];
  }
  if ([view backgroundColor] && ![[view backgroundColor] isEqual:[UIColor clearColor]]) {
    res = [view backgroundColor];
  }
  return res;
}

// take snapshot for lynx view
- (UIImage*)createImageOfView:(UIView*)view {
  UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0.0);
  auto rect = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
  [[self getBackgroundColor] setFill];
  UIRectFill(rect);
  // pass NO may get blank image when view not on screen
  [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
  UIImage* snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return snapshotImage;
}

// take snapshot for screen
- (UIImage*)createImageOfScreen:(UIView*)view {
  UIView* screenView = [UIApplication sharedApplication].keyWindow;
  UIGraphicsBeginImageContextWithOptions(screenView.frame.size, YES, 0.0);
  [screenView drawViewHierarchyInRect:screenView.bounds afterScreenUpdates:NO];
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (NSString*)Get1xJPEGBytesFromUIImage:(UIImage*)uiimage withQuality:(int)quality {
  NSData* data = UIImageJPEGRepresentation(uiimage, quality / 100.0);
  NSString* str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return str;
}

- (UIImage*)scaleImage:(UIImage*)image toScale:(float)scaleSize {
  int scaleWidth = image.size.width * scaleSize;
  int scaleHeight = image.size.height * scaleSize;
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaleWidth, scaleHeight), NO, 0);
  [image drawInRect:CGRectMake(0, 0, scaleWidth, scaleHeight)];
  UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return scaledImage;
}

#elif OS_OSX
- (NSColor*)getBackgroundColor {
  if (_lynxView == nil) {
    return nil;
  }
  NSColor* res = [NSColor whiteColor];
  return res;
}

- (NSImage*)createImageOfView:(NSView*)view {
  if (_lynxView == nil) {
    return nil;
  }
  NSWindow* window = _lynxView.window;
  CGRect rect = _lynxView.bounds;
  rect = [_lynxView convertRect:rect toView:nil];
  rect = [window convertRectToScreen:rect];
  CGRect frame = [NSScreen mainScreen].frame;
  rect.origin.y = frame.size.height - rect.size.height - rect.origin.y;

  CGImageRef cgImage = CGWindowListCreateImage(
      rect, kCGWindowListOptionIncludingWindow, CGWindowID(window.windowNumber),
      kCGWindowImageNominalResolution | kCGWindowImageBoundsIgnoreFraming);
  NSImage* image = [[NSImage alloc] initWithCGImage:cgImage size:rect.size];
  image.size = CGSizeMake(1920, 1280);
  return image;
}

- (NSImage*)createImageOfScreen:(NSView*)view {
  // We just take view snapshot on mac
  return [self createImageOfView:view];
}

- (NSString*)Get1xJPEGBytesFromUIImage:(NSImage*)uiimage withQuality:(int)quality {
  CGFloat width = uiimage.size.width;
  CGFloat height = uiimage.size.height;
  [uiimage lockFocus];
  NSBitmapImageRep* bits =
      [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, width, height)];
  [uiimage unlockFocus];
  NSDictionary* imageProps =
      [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:quality / 100.0]
                                  forKey:NSImageCompressionFactor];
  NSData* data = [bits representationUsingType:NSJPEGFileType properties:imageProps];
  NSString* str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return str;
}

- (NSImage*)scaleImage:(NSImage*)image toScale:(float)scaleSize {
  int scaleWidth = image.size.width * scaleSize;
  int scaleHeight = image.size.height * scaleSize;
  NSSize size = NSMakeSize(scaleWidth, scaleHeight);
  NSImage* scaledImage = [[NSImage alloc] initWithSize:size];
  [scaledImage lockFocus];
  [image drawInRect:CGRectMake(0, 0, scaleWidth, scaleHeight)];
  [scaledImage unlockFocus];
  return scaledImage;
}
#endif

- (float)getScallingFromWidth:(int)original_width
                       height:(int)original_height
                     maxWidth:(int)max_width
                    maxHeight:(int)max_height {
  float scaling_width = 1;
  float scaling_height = 1;
#if OS_IOS
  float screen_factor = [UIScreen mainScreen].scale;
#elif OS_OSX
  float screen_factor = [NSScreen mainScreen].backingScaleFactor;
#endif
  if (max_height != 0 && max_width != 0 &&
      ((original_width * screen_factor) > max_width ||
       (original_height * screen_factor) > max_height)) {
    scaling_width = max_width / (float)(original_width * screen_factor);
    scaling_height = max_height / (float)(original_height * screen_factor);
  }
  return scaling_width < scaling_height ? scaling_width : scaling_height;
}

- (void)startCapture:(int)quality width:(int)max_width height:(int)max_height {
  quality_ = quality;
  max_width_ = max_width;
  max_height_ = max_height;
  enabled_ = YES;
  [self attachView:_lynxView];
  [self startFrameViewTrace];
  // manually trigger first snapshot
  [self triggerNextCapture];
}

- (void)stopCapture {
  [self stopFrameViewTrace];
  enabled_ = NO;
}

- (void)onAckReceived {
  ack_received_ = YES;
}

- (void)triggerNextCapture {
  if (!self.snapshotCache || ack_received_) {
    [self screenshot];
  }
}

- (BOOL)isEnabled {
  return enabled_;
}

- (NSString*)takeSnapshot:(VIEW_CLASS*)view {
  return [self takeSnapshot:view forCardPreview:false];
}

- (NSString*)takeSnapshot:(VIEW_CLASS*)view forCardPreview:(bool)isPreview {
  if (!_lynxView || _lynxView.frame.size.width <= 0 || _lynxView.frame.size.height <= 0) {
    LLogWarn(@"failed to take snapshot and the _lynxView is %p", _lynxView);
    return nil;
  }
  IMAGE_CLASS* image = nil;
  if (isPreview) {
    image = [self createImageOfView:_lynxView];
    // only view on screen can take screenshot repeatedly
  } else if (_lynxView.window) {
    image = [self createImageOfScreen:_lynxView];
  }

  if (image == nil) {
    LLogWarn(@"failed to tack snapshot caused by nil image");
    return nil;
  }
  screen_metadata_->timestamp_ = [[NSDate date] timeIntervalSince1970];
  auto original_height = image.size.height;
  auto original_width = image.size.width;
  screen_metadata_->device_width_ = original_width;
  screen_metadata_->device_height_ = original_height;
  screen_metadata_->page_scale_factor_ = 1;
  float scalling = 1;
  int max_width = isPreview ? kCardPreviewMaxWidth : max_width_;
  int max_height = isPreview ? kCardPreviewMaxHeight : max_height_;
  int quality = isPreview ? kCardPreviewQuality : quality_;
  scalling = [self getScallingFromWidth:original_width
                                 height:original_height
                               maxWidth:max_width
                              maxHeight:max_height];
  image = [self scaleImage:image toScale:scalling];
  return [self Get1xJPEGBytesFromUIImage:image withQuality:quality];
}

- (void)onNewSnapshot:(NSString*)data {
  ack_received_ = NO;
  dispatch_async(_computeQueue, ^{
    [self->_owner sendScreenCast:data andMetadata:self->screen_metadata_];
  });
}

- (void)onFrameChanged {
  [self triggerNextCapture];
}

@end

#pragma mark - LynxScreenCastHelper
@implementation LynxScreenCastHelper {
  __weak LynxView* _lynxView;
  __weak LynxInspectorOwner* _owner;
  BOOL _paused;

  LynxInspectorOwnerScreenCastHelper* _screenCastHelper;
}

- (nonnull instancetype)initWithLynxView:(LynxView*)view withOwner:(LynxInspectorOwner*)owner {
  _lynxView = view;
  _owner = owner;
  _paused = NO;

  _screenCastHelper = [[LynxInspectorOwnerScreenCastHelper alloc] initWithLynxView:_lynxView
                                                                         withOwner:owner];
  return self;
}

- (void)startCasting:(int)quality width:(int)max_width height:(int)max_height {
  [_owner dispatchScreencastVisibilityChanged:YES];
  [_screenCastHelper startCapture:quality width:max_width height:max_height];
}

- (void)stopCasting {
  [_screenCastHelper stopCapture];
  [_owner dispatchScreencastVisibilityChanged:NO];
}

- (void)continueCasting {
  if (_paused) {
    _paused = NO;
    [_owner dispatchScreencastVisibilityChanged:YES];
    [_screenCastHelper triggerNextCapture];
  }
}

- (void)pauseCasting {
  if (!_paused) {
    _paused = YES;
    [_owner dispatchScreencastVisibilityChanged:NO];
    _screenCastHelper.snapshotCache = nil;
  }
}

- (void)attachLynxView:(nonnull LynxView*)lynxView {
  _lynxView = lynxView;
  [_screenCastHelper attachLynxView:lynxView];
}

- (void)onAckReceived {
  [_screenCastHelper onAckReceived];
}

- (NSString*)takeCardPreview {
  return [_screenCastHelper takeSnapshot:_lynxView forCardPreview:true];
}

@end
