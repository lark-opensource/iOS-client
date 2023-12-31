// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTextRendererCache.h"

#pragma mark - Helper Functino

#define LYNX_EPSILON 0.0001
#define TOTAL_COST_LIMIT (10 * 1024)  // 10K charaters for global Text Render

static bool compareNearlyEqual(CGFloat a, CGFloat b) {
  float epsilon;
  if (a == b) return true;
  if (a > b) {
    epsilon = a * LYNX_EPSILON;
  } else {
    epsilon = b * LYNX_EPSILON;
  }
  return fabs(a - b) < epsilon;
}

extern BOOL layoutManagerIsTruncated(NSLayoutManager *layoutManager) {
  NSTextContainer *container = layoutManager.textContainers.firstObject;
  NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
  __block NSRange truncatedRange;
  __block NSUInteger maxRange = NSMaxRange([layoutManager glyphRangeForTextContainer:container]);
  [layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, numberOfGlyphs)
                                          usingBlock:^(CGRect rect, CGRect usedRect,
                                                       NSTextContainer *_Nonnull textContainer,
                                                       NSRange glyphRange, BOOL *_Nonnull stop) {
                                            truncatedRange = [layoutManager
                                                truncatedGlyphRangeInLineFragmentForGlyphAtIndex:
                                                    glyphRange.location];
                                            if (truncatedRange.location != NSNotFound) {
                                              maxRange = truncatedRange.location;
                                              *stop = YES;
                                            }
                                          }];
  return numberOfGlyphs > maxRange;
}

static BOOL layoutManagerIsSingleLine(NSLayoutManager *layoutManager) {
  NSUInteger index = 0;
  NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
  NSRange lineRange;
  [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
  return NSMaxRange(lineRange) == numberOfGlyphs;
}

static NSUInteger layoutManagerLineCount(NSLayoutManager *layoutManager) {
  NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
  NSRange lineRange;
  for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++) {
    (void)[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
    index = NSMaxRange(lineRange);
  }
  return numberOfLines;
}

#pragma mark - LynxTextRendererKey

@interface LynxTextRendererKey : NSObject

- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr
                              layoutSpec:(LynxLayoutSpec *)spec;

@end

@implementation LynxTextRendererKey {
  NSAttributedString *_attrStr;
  LynxLayoutSpec *_layoutSpec;
  NSUInteger _hashValue;
}

- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr
                              layoutSpec:(LynxLayoutSpec *)spec {
  if (self = [super init]) {
    _attrStr = attrStr;
    _layoutSpec = spec;
    _hashValue = [attrStr hash] ^ [_layoutSpec hash];
  }
  return self;
}

- (BOOL)isEqual:(LynxTextRendererKey *)object {
  if (self == object) {
    return YES;
  }
  if (object == nil) {
    return NO;
  }
  return _hashValue == object->_hashValue &&
         [_attrStr isEqualToAttributedString:object->_attrStr] &&
         [_layoutSpec isEqualToSpec:object->_layoutSpec];
}

- (NSUInteger)hash {
  return _hashValue;
}

@end

#pragma mark - Cache

@implementation LynxTextRendererCache {
  NSCache<LynxTextRendererKey *, LynxTextRenderer *> *_cache;
  NSMutableDictionary<NSAttributedString *, NSMutableArray<LynxTextRenderer *> *>
      *_attrStringRenderers;
}

+ (instancetype)cache {
  static NSUInteger countLimit = 500;
  static dispatch_once_t onceToken;
  static LynxTextRendererCache *cache = nil;
  dispatch_once(&onceToken, ^{
    cache = [[LynxTextRendererCache alloc] initWithCountLimit:countLimit];
  });
  return cache;
}

- (instancetype)initWithCountLimit:(NSUInteger)countLimit {
  if (self = [super init]) {
    _cache = [[NSCache alloc] init];
    _cache.countLimit = countLimit;
    _cache.totalCostLimit = TOTAL_COST_LIMIT;
    _cache.delegate = self;
    _attrStringRenderers = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(handleMemoryWarning:)
               name:UIApplicationDidReceiveMemoryWarningNotification
             object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj {
}

- (void)clearCache {
  [_attrStringRenderers removeAllObjects];
  [_cache removeAllObjects];
}

- (void)handleMemoryWarning:(NSNotification *)notification {
  // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Notifications/Articles/Threading.html#//apple_ref/doc/uid/20001289-CEGJFDFG
  // this method maybe called on other thread, since NSDictionary is not thread save, delivering
  // this to main thread
  LynxTextRendererCache *__weak weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    LynxTextRendererCache *strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    [strongSelf->_cache removeAllObjects];
  });
}

- (LynxTextRenderer *)_suitableRendererWithString:(NSAttributedString *)str
                                       layoutSpec:(LynxLayoutSpec *)spec {
  BOOL widthUndifined = spec.widthMode == LynxMeasureModeIndefinite;
  BOOL heightUndifined = spec.heightMode == LynxMeasureModeIndefinite;
  for (LynxTextRenderer *renderer in [_attrStringRenderers objectForKey:str]) {
    NSLayoutManager *layoutManager = renderer.layoutManager;
    NSTextContainer *container = layoutManager.textContainers.firstObject;
    CGSize textSize = [layoutManager usedRectForTextContainer:container].size;
    LynxLayoutSpec *storedSpec = renderer.layoutSpec;
    if ([spec isEqualToSpec:storedSpec]) {
      return renderer;
    }
    if (spec.breakByChar != storedSpec.breakByChar) {
      // if break strategy is not same can not reuse render
      continue;
    }
    // If two renderer have different LynxBackgroundGradient, we cannot reuse them.
    if (!LynxSameLynxGradient(storedSpec.textStyle.textGradient, spec.textStyle.textGradient)) {
      continue;
    }
    if (storedSpec.textOverflow != spec.textOverflow) continue;
    if (layoutManagerIsSingleLine(layoutManager)) {
      if (([storedSpec widthUndifined] || !layoutManagerIsTruncated(layoutManager)) &&
          (widthUndifined || textSize.width <= spec.width + LYNX_EPSILON) &&
          (!widthUndifined && ABS(spec.width - storedSpec.width) < LYNX_EPSILON) &&
          ((heightUndifined && storedSpec.heightUndifined) ||
           (spec.height <= storedSpec.height + LYNX_EPSILON))) {
        return renderer;
      }
    } else {
      if (!LynxSameMeasureMode(spec.widthMode, storedSpec.widthMode) ||
          !compareNearlyEqual(spec.width, storedSpec.width) ||
          spec.maxLineNum != storedSpec.maxLineNum) {
        continue;
      }
      if ((NSUInteger)spec.maxLineNum == layoutManagerLineCount(layoutManager)) {
        continue;
      }
      if (((heightUndifined && storedSpec.heightUndifined) ||
           compareNearlyEqual(spec.height, storedSpec.height)) &&
          (storedSpec.whiteSpace == spec.whiteSpace)) {
        return renderer;
      } else {
        continue;
      }
    }
  }
  return nil;
}

- (LynxTextRenderer *)rendererWithString:(NSAttributedString *)str
                              layoutSpec:(LynxLayoutSpec *)spec {
  if (str == nil) return nil;
  LynxTextRendererKey *key = [[LynxTextRendererKey alloc] initWithAttributedString:str
                                                                        layoutSpec:spec];
  LynxTextRenderer *renderer = [_cache objectForKey:key];
  if (renderer == nil) {
    renderer = [[LynxTextRenderer alloc] initWithAttributedString:str layoutSpec:spec];
    // https://developer.apple.com/documentation/foundation/nscache/1407672-totalcostlimit?language=objc
    // to make LRU remove effect, must pass `cost` parameter
    if (![NSThread isMainThread]) {
      // Ensure cache.setObj will be called by the main thread, to avoid render being release by
      // mistake.
      LynxTextRendererCache *__weak weakSelf = self;
      dispatch_async(dispatch_get_main_queue(), ^{
        LynxTextRendererCache *strongSelf = weakSelf;
        if (strongSelf == nil) {
          return;
        }
        [strongSelf->_cache
            setObject:renderer
               forKey:key
                 cost:[[str string] maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
      });
    } else {
      [_cache setObject:renderer
                 forKey:key
                   cost:[[str string] maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    }
  }
  return renderer;
}

@end
