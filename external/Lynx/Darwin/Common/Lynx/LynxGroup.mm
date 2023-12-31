// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxGroup.h"
#import "LynxView.h"

#pragma mark - NextId
static int sNextId = 0;

#pragma mark - SingleGroupTag
static NSString* sSingleGroupTag = @"-1";

enum {
  CanvasOptimizeDefault = 0,
  CanvasOptimizeEnable,
  CanvasOptimizeDisable,
};

#pragma mark - LynxGroup
@implementation LynxGroup {
  int _numberId;
  NSMutableArray<LynxView*>* _viewList;
  int _canvasOptimize;
  bool _enableCanvas;
}

+ (nonnull NSString*)singleGroupTag {
  return sSingleGroupTag;
}

- (nonnull instancetype)initWithName:(NSString*)name {
  return [self initWithName:name withPreloadScript:nil];
}

- (nonnull instancetype)initWithName:(nonnull NSString*)name
                   withPreloadScript:(nullable NSArray*)extraJSPaths {
  if (self = [super init]) {
    _groupName = name;
    _numberId = ++sNextId;
    _identification = [NSString stringWithFormat:@"%d", _numberId];
    _preloadJSPaths = extraJSPaths;
    _viewList = [[NSMutableArray alloc] init];
    _canvasOptimize = CanvasOptimizeDefault;
  }
  return self;
}

- (nonnull instancetype)initWithName:(nonnull NSString*)name
                   withPreloadScript:(nullable NSArray*)extraJSPaths
                    useProviderJsEnv:(bool)useProviderJsEnv
                        enableCanvas:(bool)enableCanvas {
  if (self = [self initWithName:name withPreloadScript:extraJSPaths]) {
    _useProviderJsEnv = useProviderJsEnv;
    _enableCanvas = enableCanvas;
  }
  return self;
}

- (nonnull instancetype)initWithName:(nonnull NSString*)name
                   withPreloadScript:(nullable NSArray*)extraJSPaths
                    useProviderJsEnv:(bool)useProviderJsEnv
                        enableCanvas:(bool)enableCanvas
            enableCanvasOptimization:(bool)enableCanvasOptimization {
  if (self = [self initWithName:name
              withPreloadScript:extraJSPaths
               useProviderJsEnv:useProviderJsEnv
                   enableCanvas:enableCanvas]) {
    _canvasOptimize = enableCanvasOptimization ? CanvasOptimizeEnable : CanvasOptimizeDisable;
  }
  return self;
}

- (void)addLynxView:(nonnull LynxView*)view {
  [_viewList addObject:view];
}

- (bool)enableOptimizedCanvas {
  // force use optimized canvas impl
  // enable_canvas = 1 or enable_canvas_optimize = 1
  return _enableCanvas || _canvasOptimize == CanvasOptimizeEnable;
}

+ (bool)enableOptimizedCanvas:(nullable LynxGroup*)group {
  return [group enableOptimizedCanvas];
}

+ (bool)enableAnyCanvas:(nullable LynxGroup*)group {
  // force use optimized canvas impl
  return [group enableOptimizedCanvas];
}

+ (bool)enableOriginalCanvas:(nullable LynxGroup*)group {
  // force use optimized canvas impl
  return false;
}

@end
