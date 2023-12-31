// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxBackgroundManager.h"
#import "LynxBackgroundImageLayerInfo.h"
#import "LynxBackgroundInfo.h"
#import "LynxBackgroundRenderer.h"
#import "LynxBackgroundUtils.h"
#import "LynxBasicShape.h"
#import "LynxBoxShadowLayer.h"
#import "LynxBoxShadowManager.h"
#import "LynxColorUtils.h"
#import "LynxConvertUtils.h"
#import "LynxImageLoader.h"
#import "LynxImageProcessor.h"
#import "LynxService.h"
#import "LynxServiceImageProtocol.h"
#import "LynxUI+Internal.h"
#import "LynxUnitUtils.h"

NSString* NSStringFromLynxBorderRadii(LynxBorderRadii* radii) {
  return [NSString
      stringWithFormat:@"LynxBorderRadii_%f_%ld_%f_%ld_%f_%ld_%f_%ld_%f_%ld_%f_%ld_%f_%ld_%f_%ld",
                       radii->topLeftX.val, (long)radii->topLeftX.unit, radii->topLeftY.val,
                       (long)radii->topLeftY.unit, radii->topRightX.val,
                       (long)radii->topRightX.unit, radii->topRightY.val,
                       (long)radii->topRightY.unit, radii->bottomLeftX.val,
                       (long)radii->bottomLeftX.unit, radii->bottomLeftY.val,
                       (long)radii->bottomLeftY.unit, radii->bottomRightX.val,
                       (long)radii->bottomRightX.unit, radii->bottomRightY.val,
                       (long)radii->bottomRightY.unit

  ];
}

const LynxBorderRadii LynxBorderRadiiZero = {{0, 0}, {0, 0}, {0, 0}, {0, 0},
                                             {0, 0}, {0, 0}, {0, 0}, {0, 0}};

#pragma mark LynxBackgroundSubLayer
@implementation LynxBackgroundSubLayer
@end

#pragma mark LynxBorderLayer
@implementation LynxBorderLayer
@end

#pragma mark LynxBackgroundManager
@implementation LynxBackgroundManager {
  BOOL _isBorderChanged, _isBGChangedImage, _isBGChangedNoneImage, _isMaskChanged;
  BOOL _withAnimation;
  // This backgroundSize means the area in view the background can display, most time is view size,
  // not css property background-size.
  CGSize _backgroundSize;
}

- (instancetype)initWithUI:(LynxUI*)ui {
  self = [super init];
  if (self) {
    _ui = ui;
    _backgroundInfo = [[LynxBackgroundInfo alloc] init];
    _isBorderChanged = _isBGChangedImage = _isBGChangedNoneImage = NO;
    _opacity = 1;
    // TODO(fangzhou): move these properties to info
    _backgroundDrawable = [[NSMutableArray alloc] init];
    _backgroundOrigin = [[NSMutableArray alloc] init];
    _backgroundPosition = [[NSMutableArray alloc] init];
    _backgroundRepeat = [[NSMutableArray alloc] init];
    _backgroundClip = [[NSMutableArray alloc] init];
    _backgroundImageSize = [[NSMutableArray alloc] init];
    _transform = CATransform3DIdentity;
    _transformOrigin = CGPointMake(0.5, 0.5);
    _implicitAnimation = true;
    _postTranslate = CGPointZero;
    _maskImageUrlOrGradient = [[NSMutableArray alloc] init];
    _overlapRendering = NO;
    _uiBackgroundShapeLayerEnabled = LynxBgShapeLayerPropUndefine;
    _shouldRasterizeShadow = NO;
  }
  return self;
}

- (void)applyTransformOrigin:(CALayer*)layer {
  CGFloat oldAnchorX = layer.anchorPoint.x;
  CGFloat oldAnchorY = layer.anchorPoint.y;
  CGFloat anchorX = _transformOrigin.x;
  CGFloat anchorY = _transformOrigin.y;
  layer.anchorPoint = _transformOrigin;
  CGFloat newPositionX = layer.position.x + (anchorX - oldAnchorX) * layer.frame.size.width;
  CGFloat newPositionY = layer.position.y + (anchorY - oldAnchorY) * layer.frame.size.height;
  layer.position = CGPointMake(newPositionX, newPositionY);
}

- (BOOL)clearAllBackgroundDrawable {
  if ([_backgroundDrawable count] <= 0) {
    return NO;
  }
  [_backgroundDrawable removeAllObjects];
  _isBGChangedImage = YES;
  return YES;
}

- (void)clearAllBackgroundPosition {
  [_backgroundPosition removeAllObjects];
  _isBGChangedImage = YES;
}

- (void)clearAllBackgroundSize {
  [_backgroundImageSize removeAllObjects];
  _isBGChangedImage = YES;
}

- (void)clearAllBackgroundOrigin {
  [_backgroundOrigin removeAllObjects];
  _isBGChangedImage = YES;
}

- (void)clearSimpleBorder {
  CALayer* layer = _ui.view.layer;
  [layer setBorderWidth:0.0];
  [layer setCornerRadius:0.0];
  [_borderLayer setBorderWidth:0.0];
  [_borderLayer setCornerRadius:0.0];
}

- (void)addBackgroundOrigin:(LynxBackgroundOriginType)backgroundOrigin {
  [_backgroundOrigin addObject:@(backgroundOrigin)];
  _isBGChangedImage = YES;
}

- (void)addBackgroundPosition:(LynxBackgroundPosition*)backgroundPosition {
  [_backgroundPosition addObject:backgroundPosition];
  _isBGChangedImage = YES;
}

- (void)addBackgroundRepeat:(LynxBackgroundRepeatType)backgroundRepeat {
  [_backgroundRepeat addObject:@(backgroundRepeat)];
  _isBGChangedImage = YES;
}

- (void)addBackgroundClip:(LynxBackgroundClipType)backgroundClip {
  [_backgroundClip addObject:@(backgroundClip)];
  _isBGChangedImage = YES;
}

- (void)addBackgroundSize:(LynxBackgroundSize*)backgroundImageSize {
  [_backgroundImageSize addObject:backgroundImageSize];
  _isBGChangedImage = YES;
}

- (void)addMaskImage:(LynxBackgroundDrawable*)drawable {
  [_maskImageUrlOrGradient addObject:drawable];
}

- (void)addBackgroundImage:(LynxBackgroundDrawable*)drawable {
  [_backgroundDrawable addObject:drawable];
  _isBGChangedImage = YES;
}

- (void)autoAddOpacityViewWithOpacity:(CGFloat)opacity {
  if (self.ui.view.superview == nil) {
    return;
  }
  CALayer* mainLayer = _ui.view.layer;
  CALayer* superLayer = mainLayer.superlayer;
  UIView* superView = _ui.view.superview;

  if (!_opacityView) {
    _opacityView = [[UIView alloc] init];
    CALayer* opacityLayer = _opacityView.layer;
    [superView insertSubview:_opacityView belowSubview:_ui.view];
    [superLayer insertSublayer:opacityLayer below:mainLayer];
    [mainLayer removeFromSuperlayer];
    [opacityLayer addSublayer:mainLayer];
    // background layer below main layer.
    if (_backgroundLayer) {
      [_backgroundLayer removeFromSuperlayer];
      [opacityLayer insertSublayer:_backgroundLayer below:mainLayer];
    }

    // border layer should above background layer and below main layer.
    if (_borderLayer) {
      [_borderLayer removeFromSuperlayer];
      if (_ui.overflow == OVERFLOW_HIDDEN_VAL) {
        // border layer above main layer to cover border area when 'overflow:hidden
        [opacityLayer insertSublayer:_borderLayer above:mainLayer];
      } else {
        [opacityLayer insertSublayer:_borderLayer below:mainLayer];
      }
    }
    opacityLayer.frame =
        CGRectMake(0, 0, superLayer.frame.size.width, superLayer.frame.size.height);
  }
  _opacityView.layer.opaque = NO;
  _ui.view.layer.opacity = 1.0;
  _opacityView.layer.opacity = opacity;
  _opacityView.layer.masksToBounds = NO;
}

- (void)setOpacity:(CGFloat)opacity {
  _opacity = opacity;

  if (!_overlapRendering) {
    if (_backgroundLayer) {
      _backgroundLayer.opacity = opacity;
    }
    if (_borderLayer) {
      _borderLayer.opacity = opacity;
    }
  } else {
    if ((_backgroundLayer || _borderLayer)) {
      if (!_opacityView) {
        [self autoAddOpacityViewWithOpacity:_opacity];
      }
      _ui.view.layer.opacity = 1;
      _opacityView.layer.opacity = opacity;
    }
  }
}

- (void)setHidden:(BOOL)hidden {
  _hidden = hidden;
  if (_backgroundLayer) {
    _backgroundLayer.hidden = hidden;
  }
  if (_borderLayer) {
    _borderLayer.hidden = hidden;
  }
}

- (void)setPostTranslate:(CGPoint)postTranslate {
  _postTranslate = postTranslate;

  CATransform3D transform = [self getTransformWithPostTranslate];
  _ui.view.layer.transform = transform;
  [self setTransformToLayers:transform];
}

- (CATransform3D)getTransformWithPostTranslate {
  CATransform3D result = _transform;
  result.m41 = result.m41 + _postTranslate.x;
  result.m42 = result.m42 + _postTranslate.y;
  return result;
}

- (void)setTransform:(CATransform3D)transform {
  _transform = transform;
  [self setTransformToLayers:transform];
}

- (void)setTransformToLayers:(CATransform3D)transform {
  if (_backgroundLayer != nil) {
    _backgroundLayer.transform = transform;
  }
  if (_borderLayer != nil) {
    _borderLayer.transform = transform;
  }
}

- (void)setTransformOrigin:(CGPoint)transformOrigin {
  _transformOrigin = transformOrigin;
  [self setTransformOriginToLayers:transformOrigin];
}

- (void)setTransformOriginToLayers:(CGPoint)transformOrigin {
  if (_backgroundLayer != nil) {
    [self applyTransformOrigin:_backgroundLayer];
  }
  if (_borderLayer != nil) {
    [self applyTransformOrigin:_borderLayer];
  }
}

- (void)tryToLoadBackgroundImagesAutoRefresh:(BOOL)autoRefresh {
  if (![self hasBackgroundImageOrGradient]) {
    return;
  }

  NSMutableArray* curArray = self.backgroundDrawable;
  for (int i = 0; i < (int)curArray.count; ++i) {
    id item = curArray[i];
    if (![item isKindOfClass:[LynxBackgroundImageDrawable class]]) {
      continue;
    }
    NSURL* url = nil;
    if ([item isKindOfClass:[LynxBackgroundImageDrawable class]]) {
      url = ((LynxBackgroundImageDrawable*)item).url;
      if (((LynxBackgroundImageDrawable*)item).image) {
        continue;
      }
    }
    NSMutableArray* processors = [NSMutableArray new];
    __weak typeof(self) weakSelf = self;
    __weak LynxBackgroundSubBackgroundLayer* weakLayer = self.backgroundLayer;
    __weak NSMutableArray* weakArray = curArray;
    __weak LynxBackgroundImageDrawable* drawable = item;
    const int currentIndex = i;
    [[LynxImageLoader sharedInstance]
        loadImageFromURL:url
                    size:self.ui.view.bounds.size
             contextInfo:@{LynxImageFetcherContextKeyUI : self}
              processors:processors
            imageFetcher:self.ui.context.imageFetcher
               completed:^(UIImage* _Nullable image, NSError* _Nullable error,
                           NSURL* _Nullable imageURL) {
                 void (^complete)(UIImage*, NSError* _Nullable) =
                     ^(UIImage* image, NSError* _Nullable error) {
                       if (!error) {
                         if (image != nil) {
                           if (weakArray != nil && weakArray == weakSelf.backgroundDrawable) {
                             [drawable setImage:image];
                           }
                           if (autoRefresh && weakLayer != nil &&
                               weakLayer == weakSelf.backgroundLayer) {
                             if ((NSUInteger)currentIndex < weakLayer.imageArray.count) {
                               [drawable setImage:image];
                             }
                             [weakLayer setAnimatedPropsWithImage:image];
                             [weakSelf applyComplexBackground];
                           }

                           if ([weakSelf.ui.eventSet valueForKey:@"bgload"]) {
                             NSDictionary* detail = @{
                               @"height" : [NSNumber numberWithFloat:image.size.height],
                               @"width" : [NSNumber numberWithFloat:image.size.width]
                             };
                             [weakSelf.ui.context.eventEmitter
                                 dispatchCustomEvent:[[LynxDetailEvent alloc]
                                                         initWithName:@"bgload"
                                                           targetSign:weakSelf.ui.sign
                                                               detail:detail]];
                           }
                         }
                       } else {
                         NSString* errDetail =
                             [NSString stringWithFormat:@"Load backgroundImage failed: %@", error];
                         NSDictionary* errorDic = @{
                           @"src" : url.absoluteString ?: @"",
                           @"type" : @"image",
                           @"error_msg" : errDetail
                         };
                         NSString* errorJSONString = [LynxConvertUtils convertToJsonData:errorDic];
                         LynxError* err = [LynxError lynxErrorWithCode:LynxErrorCodeForResourceError
                                                               message:errorJSONString];
                         [weakSelf.ui.context didReceiveResourceError:err];

                         // FE bind error
                         NSString* errorDetail =
                             [NSString stringWithFormat:@"url:%@,%@", url, [error description]];
                         NSNumber* errorCode = [error.userInfo valueForKey:@"error_num"]
                                                   ?: [NSNumber numberWithInteger:error.code];
                         NSNumber* categorizedErrorCode = [LynxService(LynxServiceImageProtocol)
                             getMappedCategorizedPicErrorCode:errorCode];
                         NSDictionary* feErrorDic = @{
                           @"errMsg" : errorDetail ?: @"",
                           @"error_code" : errorCode ?: @-1,
                           @"lynx_categorized_code" : categorizedErrorCode ?: @-1,
                         };
                         if ([weakSelf.ui.eventSet valueForKey:@"bgerror"]) {
                           [weakSelf.ui.context.eventEmitter
                               dispatchCustomEvent:[[LynxDetailEvent alloc]
                                                       initWithName:@"bgerror"
                                                         targetSign:weakSelf.ui.sign
                                                             detail:feErrorDic]];
                         }
                       }
                     };
                 if ([NSThread isMainThread]) {
                   complete(image, error);
                 } else {
                   dispatch_async(dispatch_get_main_queue(), ^{
                     complete(image, error);
                   });
                 }
               }];
  }
}

- (BOOL)hasBackgroundImageOrGradient {
  return [self.backgroundDrawable count] != 0;
}

- (NSMutableArray*)generateBackgroundImageLayerWithSize:(CGSize)size
                                                   info:(NSMutableArray*)drawingInfo {
  if ([drawingInfo count] == 0) {
    _backgroundLayer.isAnimated = NO;
    _backgroundLayer.animatedImageDuration = 0;
    return nil;
  }

  NSMutableArray* layerInfoArray = [[NSMutableArray alloc] init];
  CGRect borderRect = {.size = size};
  CGRect paddingRect = [_backgroundInfo getPaddingRect:size];
  CGRect contentRect = [_backgroundInfo getContentRect:paddingRect];
  UIEdgeInsets paddingInsets = [_backgroundInfo getPaddingInsets];

  CGRect clipRect = borderRect;
  LynxCornerInsets cornerInsets =
      LynxGetCornerInsets(borderRect, [_backgroundInfo borderRadius], UIEdgeInsetsZero);
  LynxBackgroundClipType clipType = LynxBackgroundClipBorderBox;

  NSMutableArray* curArray = drawingInfo;
  for (int i = 0; i < (int)curArray.count; ++i) {
    LynxBackgroundImageLayerInfo* layerInfo = [[LynxBackgroundImageLayerInfo alloc] init];
    [layerInfo setItem:curArray[i]];
    [layerInfoArray addObject:layerInfo];
    if ([layerInfo.item isKindOfClass:[LynxBackgroundImageDrawable class]]) {
      [_backgroundLayer
          setAnimatedPropsWithImage:((LynxBackgroundImageDrawable*)layerInfo.item).image];
    }

    // decide origin position
    CGRect paintingBox = paddingRect;
    LynxBackgroundOriginType usedOrigin = LynxBackgroundOriginPaddingBox;
    if ([_backgroundOrigin count] != 0) {
      int usedOriginIndex = i % [_backgroundOrigin count];
      usedOrigin = [_backgroundOrigin[usedOriginIndex] integerValue];
      switch (usedOrigin) {
        case LynxBackgroundOriginPaddingBox:
          paintingBox = paddingRect;
          break;
        case LynxBackgroundOriginBorderBox:
          paintingBox = borderRect;
          break;
        case LynxBackgroundOriginContentBox:
          paintingBox = contentRect;
          break;
        default:
          break;
      }
    }

    if ([_backgroundClip count] != 0) {
      int usedClipIndex = i % [_backgroundClip count];
      clipType = [_backgroundClip[usedClipIndex] integerValue];
      switch (clipType) {
        case LynxBackgroundClipPaddingBox:
          clipRect = paddingRect;
          cornerInsets = LynxGetCornerInsets(borderRect, [_backgroundInfo borderRadius],
                                             [self getAdjustedBorderWidth]);
          break;
        case LynxBackgroundClipContentBox:
          clipRect = contentRect;
          cornerInsets =
              LynxGetCornerInsets(borderRect, [_backgroundInfo borderRadius], paddingInsets);
          break;
        default:
          clipRect = borderRect;
          cornerInsets =
              LynxGetCornerInsets(borderRect, [_backgroundInfo borderRadius], UIEdgeInsetsZero);
          break;
      }
    }

    layerInfo.backgroundOrigin = usedOrigin;
    layerInfo.paintingRect = paintingBox;
    layerInfo.clipRect = clipRect;
    layerInfo.contentRect = contentRect;
    layerInfo.borderRect = borderRect;
    layerInfo.paddingRect = paddingRect;
    layerInfo.backgroundClip = clipType;
    layerInfo.cornerInsets = cornerInsets;

    // set background image size
    if ([_backgroundImageSize count] >= 2) {
      if ((NSUInteger)i * 2 >= [_backgroundImageSize count]) {
        layerInfo.backgroundSizeX = _backgroundImageSize[_backgroundImageSize.count - 2];
        layerInfo.backgroundSizeY = _backgroundImageSize[_backgroundImageSize.count - 1];
      } else {
        layerInfo.backgroundSizeX = _backgroundImageSize[i * 2];
        layerInfo.backgroundSizeY = _backgroundImageSize[i * 2 + 1];
      }
    }

    // set background repeatType
    LynxBackgroundRepeatType repeatXType = LynxBackgroundRepeatRepeat;
    LynxBackgroundRepeatType repeatYType = LynxBackgroundRepeatRepeat;
    if ([_backgroundRepeat count] >= 2) {
      const int usedRepeatIndex = i % ([_backgroundRepeat count] / 2);
      repeatXType = [((NSNumber*)_backgroundRepeat[usedRepeatIndex * 2]) integerValue];
      repeatYType = [((NSNumber*)_backgroundRepeat[usedRepeatIndex * 2 + 1]) integerValue];
    }
    layerInfo.repeatXType = repeatXType;
    layerInfo.repeatYType = repeatYType;

    // set background position
    if ([_backgroundPosition count] >= 2) {
      int usedPosIndex = i % ([_backgroundPosition count] / 2);
      layerInfo.backgroundPosX = _backgroundPosition[usedPosIndex * 2];
      layerInfo.backgroundPosY = _backgroundPosition[usedPosIndex * 2 + 1];
    }
  }
  return layerInfoArray;
}

- (void)removeAllAnimations {
  if (_backgroundLayer != nil) {
    [_backgroundLayer removeAllAnimations];
  }
  if (_borderLayer != nil) {
    [_borderLayer removeAllAnimations];
  }
}

- (void)addAnimationToViewAndLayers:(CAAnimation*)anim forKey:(nullable NSString*)key {
  [_ui.view.layer addAnimation:anim forKey:key];

  if (_backgroundLayer != nil) {
    [_backgroundLayer addAnimation:anim forKey:key];
  }
  if (_borderLayer != nil) {
    [_borderLayer addAnimation:anim forKey:key];
  }
}

- (void)setWithAnimation {
  if (_withAnimation) {
    return;
  }

  _withAnimation = YES;

  if ((_backgroundLayer == nil || !(_backgroundLayer.type == LynxBgTypeComplex)) &&
      LynxHasBorderRadii([_backgroundInfo borderRadius])) {
    if (_backgroundLayer == nil) {
      [self autoAddBackgroundLayer:YES];
    } else {
      _backgroundLayer.type = LynxBgTypeComplex;
      _backgroundLayer.cornerRadius = 0;
      _backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
    }
    [self applyComplexBackground];
  }
}

- (void)addAnimation:(CAAnimation*)anim forKey:(nullable NSString*)key {
  if ([key isEqualToString:@"DUP-transition-opacity"] && _overlapRendering) {
    if (_opacityView) {
      [_opacityView.layer addAnimation:anim forKey:key];
    }
  } else {
    if (_backgroundLayer != nil) {
      [_backgroundLayer addAnimation:anim forKey:key];
    }

    if (_borderLayer != nil) {
      [_borderLayer addAnimation:anim forKey:key];
    }
  }
}

- (int)animationOptions {
  int opts = 0;
  if (_borderLayer != nil) {
    opts |= LynxAnimOptHasBorderLayer;
    if (LynxBgTypeSimple != _borderLayer.type) {
      opts |= LynxAnimOptHasBorderComplex;
    }
  }
  if (_backgroundLayer != nil) {
    opts |= LynxAnimOptHasBGLayer;
    if (_backgroundLayer.type == LynxBgTypeComplex) {
      opts |= LynxAnimOptHasBGComplex;
    }
  }
  return opts;
}

- (int)animationLayerCount {
  int count = 0;
  if (_borderLayer != nil) {
    ++count;
  }
  if (_backgroundLayer != nil) {
    ++count;
  }
  return count;
}

- (void)removeAnimationForKey:(NSString*)key {
  if (_backgroundLayer != nil) {
    [_backgroundLayer removeAnimationForKey:key];
  }
  if (_borderLayer != nil) {
    [_borderLayer removeAnimationForKey:key];
  }
}

- (void)removeBorderLayer {
  if (_borderLayer != nil) {
    [_borderLayer removeAllAnimations];
    [_borderLayer removeFromSuperlayer];
    _borderLayer = nil;
  }
}

/// Apply border related props to the corresponding layer. When the view's 4 borders have same
/// `border-color`, `border-width`, `border-radius` and `border-style`, the border can be presented
/// via `CALayer`'s props. We use `borderLayer` to manage the layer hierarchy, `borderLayer` could
/// be above or below `view.layer`. Always put borders on `borderLayer` if it exists.
- (void)applySimpleBorder {
  CALayer* layer = _ui.view.layer;
  // If borderLayer exists, all border related props (radius, borderWidth, borderColor) should be
  // applied to borderLayer.
  if (_borderLayer) {
    // Clear border on view.layer and apply border on _borderLayer.
    [layer setBorderWidth:.0f];
    layer = _borderLayer;
  }
  if ([_backgroundInfo borderLeftStyle] != LynxBorderStyleNone &&
      [_backgroundInfo borderLeftStyle] != LynxBorderStyleHidden) {
    layer.borderWidth = [self getAdjustedBorderWidth].bottom;
  } else {
    layer.borderWidth = 0.0;
  }
  // Adjust radius, radius should smaller than half of the corresponding edge's length.
  // Simple border means all cornerRadius are the same.
  layer.cornerRadius = [self adjustRadius:[_backgroundInfo borderRadius].topLeftX.val
                                   bySize:layer.frame.size];
  if ([_backgroundInfo borderBottomColor]) {
    layer.borderColor = [_backgroundInfo borderBottomColor].CGColor;
  }
}

- (CALayer*)autoAddBorderLayer:(LynxBgTypes)type {
  if (_borderLayer == nil) {
    _borderLayer = [[LynxBorderLayer alloc] init];
    _borderLayer.delegate = self;
    _borderLayer.type = LynxBgTypeSimple;
    [_ui.animationManager notifyBGLayerAdded];
  }
  _borderLayer.masksToBounds = NO;
  _borderLayer.hidden = _hidden;
  _borderLayer.type = type;
  _borderLayer.transform = CATransform3DIdentity;
  _borderLayer.frame = _ui.view.layer.frame;
  _borderLayer.transform = _transform;
  _borderLayer.allowsEdgeAntialiasing = _allowsEdgeAntialiasing;
  if (_ui.enableNewTransformOrigin) {
    [self applyTransformOrigin:_borderLayer];
  }
  CALayer* superLayer = _ui.view.layer.superlayer;
  if (superLayer != nil && _borderLayer.superlayer != superLayer) {
    if (_ui.overflow != 0) {
      [superLayer insertSublayer:_borderLayer below:_ui.view.layer];
      if (_backgroundLayer != nil) {
        [superLayer insertSublayer:_backgroundLayer below:_borderLayer];
      }
    } else {
      [superLayer insertSublayer:_borderLayer above:_ui.view.layer];
    }
  }
  return _borderLayer;
}

- (void)autoAddOutlineLayer {
  if (self.ui.view.superview == nil || self.borderLayer == nil) {
    return;
  }

  if (_outlineLayer != nil) {
    [_outlineLayer removeFromSuperlayer];
  }
  if (_backgroundInfo.outlineStyle != LynxBorderStyleNone && _backgroundInfo.outlineWidth > 0) {
    if (_outlineLayer == nil) {
      _outlineLayer = [[CALayer alloc] init];
      _outlineLayer.allowsEdgeAntialiasing = _allowsEdgeAntialiasing;
    }
    if (LynxUpdateOutlineLayer(_outlineLayer, _backgroundSize, _backgroundInfo.outlineStyle,
                               _backgroundInfo.outlineColor, _backgroundInfo.outlineWidth)) {
      [_borderLayer addSublayer:_outlineLayer];
    } else {
      _outlineLayer = nil;
    }
  } else {
    _outlineLayer = nil;
  }
}

- (void)removeBackgroundLayer {
  if (_backgroundLayer != nil) {
    [_backgroundLayer removeAllAnimations];
    [_backgroundLayer removeFromSuperlayer];
    // set delegate to nil to remove displayLlink
    _backgroundLayer.delegate = nil;
    _backgroundLayer = nil;
  }
}

- (void)removeMaskLayer {
  if (_maskLayer) {
    [_maskLayer removeAllAnimations];
    [_maskLayer removeFromSuperlayer];
    _maskLayer = nil;
  }
}

- (CALayer*)addMaskLayer {
  if (!_maskLayer) {
    _maskLayer = [[LynxBackgroundSubLayer alloc] init];
    _maskLayer.delegate = self;
    [_ui.animationManager notifyBGLayerAdded];
  }
  _maskLayer.masksToBounds = NO;
  _maskLayer.opacity = _opacity;
  _maskLayer.hidden = _hidden;
  _maskLayer.type = LynxBgTypeComplex;
  _maskLayer.transform = CATransform3DIdentity;
  _maskLayer.frame = self.ui.view.layer.frame;
  _maskLayer.transform = _transform;
  if (_ui.enableNewTransformOrigin) {
    [self applyTransformOrigin:_maskLayer];
  }
  _maskLayer.allowsEdgeAntialiasing = _allowsEdgeAntialiasing;
  CALayer* superLayer = _ui.view.layer.superlayer;
  if (superLayer != nil && _maskLayer.superlayer != superLayer) {
    if (_borderLayer) {
      [superLayer insertSublayer:_maskLayer above:_borderLayer];
    } else {
      if (_ui.overflow != 0) {
        [superLayer insertSublayer:_maskLayer below:_ui.view.layer];
      } else {
        [superLayer insertSublayer:_maskLayer above:_ui.view.layer];
      }
    }
  }
  return _maskLayer;
}

- (CALayer*)autoAddBackgroundLayer:(BOOL)complex {
  if (!_backgroundLayer) {
    _backgroundLayer = [[LynxBackgroundSubBackgroundLayer alloc] init];
    _backgroundLayer.delegate = self;
    [_ui.animationManager notifyBGLayerAdded];
  }
  _backgroundLayer.masksToBounds = NO;
  _backgroundLayer.hidden = _hidden;
  _backgroundLayer.type = complex ? LynxBgTypeComplex : LynxBgTypeSimple;
  // reset transform before change frame, otherwise the result value of frame is undefined.
  _backgroundLayer.transform = CATransform3DIdentity;
  _backgroundLayer.frame = self.ui.view.layer.frame;
  _backgroundLayer.transform = _transform;
  if (_ui.enableNewTransformOrigin) {
    [self applyTransformOrigin:_backgroundLayer];
  }
  _backgroundLayer.allowsEdgeAntialiasing = _allowsEdgeAntialiasing;
  _backgroundLayer.enableAsyncDisplay = self.ui.enableAsyncDisplay;
  _backgroundLayer.backgroundColorClip =
      [_backgroundClip count] == 0
          ? LynxBackgroundClipBorderBox
          : (LynxBackgroundClipType)[[_backgroundClip lastObject] integerValue];
  _backgroundLayer.paddingWidth = _backgroundInfo.paddingWidth;

  _ui.view.backgroundColor = [UIColor clearColor];
  if (!complex) {
    _backgroundLayer.cornerRadius = [self adjustRadius:[_backgroundInfo borderRadius].topLeftX.val
                                                bySize:_backgroundLayer.frame.size];
    _backgroundLayer.backgroundColor = _backgroundInfo.backgroundColor.CGColor;
  }

  CALayer* superLayer = _ui.view.layer.superlayer;

  if (superLayer != nil && _backgroundLayer.superlayer != superLayer) {
    if (_ui.overflow != 0 && _borderLayer != nil) {
      [superLayer insertSublayer:_borderLayer below:_ui.view.layer];
      [superLayer insertSublayer:_backgroundLayer below:_borderLayer];
    } else {
      [superLayer insertSublayer:_backgroundLayer below:_ui.view.layer];
    }
  }
  return _backgroundLayer;
}

- (void)applyComplexBackground {
  _backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
  _backgroundLayer.cornerRadius = 0;
  if (_isBGChangedImage) {
    _backgroundLayer.isAnimated = NO;
    [self tryToLoadBackgroundImagesAutoRefresh:YES];

    _backgroundLayer.imageArray = [self generateBackgroundImageLayerWithSize:_backgroundSize
                                                                        info:_backgroundDrawable];
  }
  [_backgroundLayer markDirtyWithSize:self->_backgroundSize
                                radii:self->_borderRadius
                         borderInsets:self->_borderWidth
                      backgroundColor:self->_backgroundColor
                           drawToEdge:NO
                            capInsets:self->_backgroundCapInsets.capInsets];
}

- (void)getBackgroundImageAsync:(NSArray*)imageArrayInfo withCompletion:completionBlock {
  if (!imageArrayInfo) {
    imageArrayInfo = [[NSArray alloc] initWithArray:self->_backgroundLayer.imageArray];
  }

  // deep copy: thread safe
  CGSize backgroundSizeCopy = self->_backgroundSize;
  LynxBorderRadii borderRadiusCopy = [_backgroundInfo borderRadius];
  UIEdgeInsets borderWidthCopy = [self getAdjustedBorderWidth];
  UIColor* backgroundColorCopy = [[_backgroundInfo backgroundColor] copy];

  __weak LynxBackgroundManager* weakSelf = self;
  lynx_async_get_background_image_block_t displayBlock = ^{
    __strong LynxBackgroundManager* strongSelf = weakSelf;
    if (strongSelf) {
      return LynxGetBackgroundImage(backgroundSizeCopy, borderRadiusCopy, borderWidthCopy,
                                    backgroundColorCopy.CGColor, NO, imageArrayInfo);
    }
    return (UIImage*)nil;
  };
  [self.ui displayComplexBackgroundAsynchronouslyWithDisplay:displayBlock
                                                  completion:completionBlock];
}

- (void)dealloc {
  if (_backgroundLayer && _backgroundLayer.delegate == self) {
    _backgroundLayer.delegate = nil;
  }
  if (_borderLayer && _borderLayer.delegate == self) {
    _borderLayer.delegate = nil;
  }
}

- (BOOL)toAddSubLayerOnBorderLayer {
  if (_backgroundInfo.outlineStyle != LynxBorderStyleNone) {
    // outlines are attached onto border the layer
    return YES;
  }

  return NO;
}

- (BOOL)toAddSubLayerOnBackgroundLayer {
  if ([_shadowArray count] != 0) {
    // shadows are attached onto background layer
    return YES;
  }

  if (_ui.overflow != 0) {
    return YES;
  }

  return NO;
}

- (BOOL)isSimpleBackground {
  if ([_backgroundClip count] != 0) {
    // should clip background color
    return NO;
  }

  if ([_backgroundInfo hasDifferentBorderRadius]) {
    // normal layer do not support different radius
    return NO;
  }

  if ([_backgroundDrawable count] != 0) {
    return NO;
  }

  if ([_shadowArray count] != 0) {
    for (LynxBoxShadow* shadow in _shadowArray) {
      if (shadow.inset) {
        // background of view will hide the inset shader, so we use complex mode
        return NO;
      }
    }
  }

  return YES;
}

- (id<CAAction>)actionForLayer:(CALayer*)layer forKey:(NSString*)event {
  if (!_implicitAnimation)
    return (id)[NSNull null];  // disable all implicit animations
  else
    return nil;  // allow implicit animations
}

- (float)adjustRadius:(float)radius bySize:(CGSize)size {
  if (radius + radius > size.width) {
    radius = size.width * 0.5f;
  }
  if (radius + radius > size.height) {
    radius = size.height * 0.5f;
  }
  return radius;
}

- (UIEdgeInsets)getAdjustedBorderWidth {
  CGFloat top = (_backgroundInfo.borderTopStyle == LynxBorderStyleNone ||
                 _backgroundInfo.borderTopStyle == LynxBorderStyleHidden)
                    ? 0
                    : _backgroundInfo.borderWidth.top;
  CGFloat left = (_backgroundInfo.borderLeftStyle == LynxBorderStyleNone ||
                  _backgroundInfo.borderLeftStyle == LynxBorderStyleHidden)
                     ? 0
                     : _backgroundInfo.borderWidth.left;
  CGFloat bottom = (_backgroundInfo.borderBottomStyle == LynxBorderStyleNone ||
                    _backgroundInfo.borderBottomStyle == LynxBorderStyleHidden)
                       ? 0
                       : _backgroundInfo.borderWidth.bottom;
  CGFloat right = (_backgroundInfo.borderRightStyle == LynxBorderStyleNone ||
                   _backgroundInfo.borderRightStyle == LynxBorderStyleHidden)
                      ? 0
                      : _backgroundInfo.borderWidth.right;
  return UIEdgeInsetsMake(top, left, bottom, right);
}

// CAShapeLayer is enabled to substitute CALayer for rendering background & border.
- (BOOL)isBackgroundShapeLayerEnabled {
  bool ret = false;
  switch (_uiBackgroundShapeLayerEnabled) {
    case LynxBgShapeLayerPropUndefine:
      ret = _ui.context.enableBackgroundShapeLayer;
      break;
    case LynxBgShapeLayerPropEnabled:
      ret = true;
      break;
    case LynxBgShapeLayerPropDisabled:
      ret = false;
      break;
  }
  return ret;
}

// for detailed comments, see them on LynxBackgroundManager.h
- (void)applyEffect {
  if (!_ui || !_ui.view) {
    return;
  }

  // to get the real size, reset the transform
  CATransform3D layerTransform = _ui.view.layer.transform;
  _ui.view.layer.transform = CATransform3DIdentity;
  const CGSize newViewSize = CGSizeMake(_ui.view.frame.size.width, _ui.view.frame.size.height);
  const BOOL isSizeChanged = !CGSizeEqualToSize(_backgroundSize, newViewSize);
  if (_isBorderChanged && [_backgroundInfo borderChanged] &&
      (isSizeChanged || _isBGChangedNoneImage || [_backgroundInfo BGChangedNoneImage])) {
    // size or border radius changed, adjust the mask
    [_ui updateLayerMaskOnFrameChanged];
  }
  _ui.view.layer.transform = layerTransform;

  const BOOL hasDifferentBorderRadius = [_backgroundInfo hasDifferentBorderRadius];
  const BOOL isSimpleBorder = [_backgroundInfo isSimpleBorder];
  const BOOL noBorderLayer = isSimpleBorder && ![self toAddSubLayerOnBorderLayer] &&
                             (OVERFLOW_HIDDEN_VAL == _ui.overflow || ![_backgroundInfo hasBorder]);
  const BOOL isSimpleBackground = [self isSimpleBackground];
  const BOOL noBackgroundLayer = isSimpleBackground && ![self toAddSubLayerOnBackgroundLayer];
  // noMaskLayer = the view shouldn't contain a mask layer
  const BOOL noMaskLayer = [_maskImageUrlOrGradient count] == 0 ? YES : NO;

  if (isSizeChanged) {
    _backgroundSize = newViewSize;
    if (!noBorderLayer) {
      _isBorderChanged = YES;
    }
    if (!noBackgroundLayer) {
      _isBGChangedImage = YES;
    }
    if (!noMaskLayer) {
      _isMaskChanged = YES;
    }
  }

  LynxBgTypes borderType =
      isSimpleBorder ? LynxBgTypeSimple
      : ([_backgroundInfo canUseBorderShapeLayer] && [self isBackgroundShapeLayerEnabled])
          ? LynxBgTypeShape
          : LynxBgTypeComplex;

  if (_isBorderChanged || [_backgroundInfo borderChanged]) {
    if (noBorderLayer) {
      [self removeBorderLayer];
      [self applySimpleBorder];
      _isBorderChanged = NO;
    } else if (_backgroundSize.width > 0 || _backgroundSize.height > 0 || isSizeChanged) {
      [self autoAddBorderLayer:borderType];
      if (LynxBgTypeSimple == borderType) {
        [_borderLayer setContents:nil];
        [_borderLayer setPath:nil];
        [self applySimpleBorder];
      } else if (LynxBgTypeShape == borderType) {
        CGPathRef borderPath = [_backgroundInfo getBorderLayerPathWithSize:_backgroundSize];
        // Clear simple border and complex border
        [self clearSimpleBorder];
        [_borderLayer setContents:nil];
        LynxUpdateBorderLayerWithPath(_borderLayer, borderPath, _backgroundInfo);
        CGPathRelease(borderPath);
      } else {
        [self clearSimpleBorder];
        [_borderLayer setPath:nil];
        // TODO(fangzhou):move this function to draw module
        UIImage* image = [_backgroundInfo getBorderLayerImageWithSize:_backgroundSize];
        LynxUpdateLayerWithImage(_borderLayer, image);
      }
      [self autoAddOutlineLayer];
      _isBorderChanged = NO;
    }
  }

  if (_isBGChangedImage || _isBGChangedNoneImage || [_backgroundInfo BGChangedImage] ||
      [_backgroundInfo BGChangedNoneImage]) {
    if (noBackgroundLayer) {
      [self removeBackgroundLayer];
      _ui.view.backgroundColor = [_backgroundInfo backgroundColor];
      _ui.view.layer.cornerRadius = [self adjustRadius:[_backgroundInfo borderRadius].topLeftX.val
                                                bySize:newViewSize];
      _isBGChangedImage = _isBGChangedNoneImage = NO;
      _backgroundInfo.BGChangedImage = _backgroundInfo.BGChangedNoneImage = NO;
    } else if (_backgroundSize.width > 0 || _backgroundSize.height > 0 || isSizeChanged) {
      if (nil != _backgroundLayer && _backgroundDrawable.count == 0) {
        _backgroundLayer.contents = nil;
      }
      [self autoAddBackgroundLayer:!isSimpleBackground];
      if (!isSimpleBackground) {
        [self applyComplexBackground];
      }
      [self updateShadow];
      _isBGChangedImage = _isBGChangedNoneImage = NO;
      _backgroundInfo.BGChangedImage = _backgroundInfo.BGChangedNoneImage = NO;
    }
  }

  if (_isMaskChanged) {
    if (noMaskLayer) {
      [self removeMaskLayer];
    } else if (_backgroundSize.width > 0 || _backgroundSize.height > 0 || isSizeChanged) {
      [self addMaskLayer];
      _maskLayer.imageArray = [self generateBackgroundImageLayerWithSize:_backgroundSize
                                                                    info:_maskImageUrlOrGradient];
      UIImage* maskImage = LynxGetBackgroundImage(
          _backgroundSize, [_backgroundInfo borderRadius], [self getAdjustedBorderWidth],
          [UIColor clearColor].CGColor, NO, _maskLayer.imageArray);
      adjustInsets(maskImage, _maskLayer, self->_backgroundCapInsets.capInsets);
    }
  }

  if (hasDifferentBorderRadius) {
    _ui.view.layer.cornerRadius = 0;
  } else {
    // if radius values of all corners are same, just use layer cornerRadius
    _ui.view.layer.cornerRadius = [self adjustRadius:[_backgroundInfo borderRadius].topLeftX.val
                                              bySize:newViewSize];
  }

  if (!CGSizeEqualToSize(newViewSize, CGSizeZero) || _withAnimation) {
    // if lynxUI has sticky attribute, transform = _transform + stickyTransform
    // else transform is default _transform
    CATransform3D transformWithSticky = [self getTransformWithPostTranslate];

    _ui.view.layer.transform = CATransform3DIdentity;

    if (_backgroundLayer != nil) {
      // reset transform before change frame, otherwise the result value of frame is undefined.
      _backgroundLayer.transform = CATransform3DIdentity;
      _backgroundLayer.frame = _ui.view.layer.frame;
      _backgroundLayer.transform = transformWithSticky;
      _backgroundLayer.mask = nil;
      if (_ui.clipPath) {
        CAShapeLayer* mask = [[CAShapeLayer alloc] init];
        UIBezierPath* path = [_ui.clipPath pathWithFrameSize:_ui.frameSize];
        mask.path = path.CGPath;
        _backgroundLayer.mask = mask;
      }
    }

    if (_borderLayer != nil) {
      _borderLayer.transform = CATransform3DIdentity;
      _borderLayer.frame = _ui.view.layer.frame;
      _borderLayer.transform = transformWithSticky;
      _borderLayer.mask = nil;
      if (_ui.clipPath) {
        CAShapeLayer* mask = [[CAShapeLayer alloc] init];
        UIBezierPath* path = [_ui.clipPath pathWithFrameSize:_ui.frameSize];
        mask.path = path.CGPath;
        _borderLayer.mask = mask;
      }
    }

    if (!CATransform3DIsIdentity(transformWithSticky)) {
      _ui.view.layer.transform = transformWithSticky;
    }
  }

  // apply opacity on layers.
  [self setOpacity:_opacity];
}

- (void)getBackgroundImageForContentsAnimationAsync:(void (^)(UIImage*))completionBlock
                                           withSize:(CGSize)size {
  [self setWithAnimation];
  NSMutableArray* bgImgInfoArr = [self generateBackgroundImageLayerWithSize:size
                                                                       info:_backgroundDrawable];
  [self getBackgroundImageAsync:bgImgInfoArr withCompletion:completionBlock];
}

- (UIImage*)getBackgroundImageForContentsAnimationWithSize:(CGSize)size {
  [self setWithAnimation];
  NSMutableArray* bgImgInfoArr = [self generateBackgroundImageLayerWithSize:size
                                                                       info:_backgroundDrawable];
  UIImage* image =
      LynxGetBackgroundImage(size, [_backgroundInfo borderRadius], [self getAdjustedBorderWidth],
                             [_backgroundInfo backgroundColor].CGColor, NO, bgImgInfoArr);
  return image;
}

- (UIImage*)getBorderImageForContentsAnimationWithSize:(CGSize)size {
  UIImage* image = [_backgroundInfo getBorderLayerImageWithSize:size];
  return image;
}

- (CGPathRef)getBorderPathForAnimationWithSize:(CGSize)size {
  CGPathRef path = [_backgroundInfo getBorderLayerPathWithSize:size];
  return path;
}

- (UIImage*)getBackgroundImageForContentsAnimation {
  return [self getBackgroundImageForContentsAnimationWithSize:_backgroundSize];
}

- (void)removeShadowLayers {
  for (LynxBoxShadow* shadow in _shadowArray) {
    if (shadow.layer != nil) {
      [shadow.layer removeFromSuperlayer];
    }
  }
}

- (void)setShadowArray:(NSArray<LynxBoxShadow*>*)shadowArrayIn {
  const NSUInteger count = [_shadowArray count];
  if (count == [shadowArrayIn count]) {
    bool allSame = true;
    for (size_t i = 0; i < count; ++i) {
      if (![_shadowArray[i] isEqualToBoxShadow:shadowArrayIn[i]]) {
        allSame = false;
        break;
      }
    }
    if (allSame) return;
  }

  [self removeShadowLayers];

  _shadowArray = shadowArrayIn;

  _isBGChangedNoneImage = YES;
}

- (void)updateShadow {
  if (self.ui.view.superview == nil || self.backgroundLayer == nil) {
    return;
  }

  CALayer* lastInsetLayer = nil;
  const bool hasBorderRadii = LynxHasBorderRadii([_backgroundInfo borderRadius]);

  for (LynxBoxShadow* shadow in _shadowArray) {
    if (shadow.layer != nil) {
      [shadow.layer removeFromSuperlayer];
    }

    // TODO(renzhongyue): rasterize shadow with spreadRadius. Now the shouldRasterizeShadow will
    // only shadows without spread radius on bitmap backends.
    // -[LynxBackgroundManager shouldRasterize] is an attribute set by front end.
    const BOOL hasSpreadRadius = shadow.spreadRadius != 0;
    const BOOL rasterizeShadow = _shouldRasterizeShadow && !hasSpreadRadius;

    CALayer* layer;
    if (!rasterizeShadow) {
      layer = [CALayer new];
      layer.shadowColor = shadow.shadowColor.CGColor;
      layer.shadowOpacity = 1.0f;
      layer.shadowRadius = shadow.blurRadius * 0.5f;
      layer.shadowOffset = CGSizeMake(shadow.offsetX, shadow.offsetY);
    } else {
      layer = [[LynxBoxShadowLayer alloc] initWithUi:_ui];
      [(LynxBoxShadowLayer*)layer setCustomShadowBlur:shadow.blurRadius];
      [(LynxBoxShadowLayer*)layer setCustomShadowColor:shadow.shadowColor];
      [(LynxBoxShadowLayer*)layer setCustomShadowOffset:CGSizeMake(shadow.offsetX, shadow.offsetY)];
      [(LynxBoxShadowLayer*)layer setInset:shadow.inset];
    }

    // Common props for rasterized shadow and UIKit shadowPath.
    shadow.layer = layer;
    layer.frame = self.backgroundLayer.bounds;  // sub layer
    layer.masksToBounds = NO;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.allowsEdgeAntialiasing = _allowsEdgeAntialiasing;

    const float maxInset = MIN(layer.bounds.size.width, layer.bounds.size.height) * 0.5f;
    const float inset = MAX(shadow.spreadRadius, -maxInset);

    if (shadow.inset) {
      CGMutablePathRef maskPath = CGPathCreateMutable(), path = CGPathCreateMutable();
      const CGRect innerRect = CGRectInset(layer.bounds, inset, inset);
      if (!hasBorderRadii) {
        LynxPathAddRect(path, innerRect, false);
        CGPathAddRect(maskPath, nil, layer.bounds);
      } else {
        UIEdgeInsets borders;
        borders.top = borders.right = borders.bottom = borders.left = inset;
        LynxPathAddRoundedRect(
            path, LynxGetRectWithEdgeInsets(layer.bounds, borders),
            LynxGetCornerInsets(layer.bounds, [_backgroundInfo borderRadius], borders));
        LynxPathAddRoundedRect(
            maskPath, layer.bounds,
            LynxGetCornerInsets(layer.bounds, [_backgroundInfo borderRadius], UIEdgeInsetsZero));
      }
      // inverse outer rect large enough is ok
      const CGRect outerRect = CGRectInset(
          CGRectUnion(innerRect, CGRectOffset(layer.bounds, -shadow.offsetX, -shadow.offsetY)),
          -300, -300);
      LynxPathAddRect(path, outerRect, true);

      // Set path to layer, LynxShadowLayer use customized rendering function to avoid off-screen
      // rendering, don't set value to CALayer's props. But CoreGraphics don't have blur effect or
      // shadow spread effect. Shadows with spreadRadius should still use CALayer's shadowPath
      // property.
      if (!rasterizeShadow) {
        layer.shadowPath = path;
        // clip by the real round rect
        CAShapeLayer* shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.path = maskPath;
        layer.mask = shapeLayer;
      } else {
        [(LynxBoxShadowLayer*)layer setCustomShadowPath:path];
        [(LynxBoxShadowLayer*)layer setMaskPath:maskPath];
        layer.frame = outerRect;
        [(LynxBoxShadowLayer*)layer invalidate];
      }

      // add above all background images, keep the order
      if (lastInsetLayer != nil) {
        [_backgroundLayer insertSublayer:layer below:lastInsetLayer];
      } else {
        [_backgroundLayer addSublayer:layer];
      }
      lastInsetLayer = layer;
      CGPathRelease(path);
      CGPathRelease(maskPath);
    } else {
      CGMutablePathRef maskPath = CGPathCreateMutable();
      CGPathRef path = nil;
      if (!hasBorderRadii) {
        CGPathAddRect(maskPath, nil, layer.bounds);
        path = CGPathRetain(
            [UIBezierPath bezierPathWithRect:CGRectInset(layer.bounds, -shadow.spreadRadius,
                                                         -shadow.spreadRadius)]
                .CGPath);

      } else {
        path = LynxPathCreateWithRoundedRect(
            layer.bounds,
            LynxGetCornerInsets(layer.bounds, [_backgroundInfo borderRadius], UIEdgeInsetsZero));
        CGPathAddPath(maskPath, nil, path);
        CGPathRelease(path);

        UIEdgeInsets borders;
        borders.top = borders.right = borders.bottom = borders.left = -shadow.spreadRadius;
        path = LynxPathCreateWithRoundedRect(
            LynxGetRectWithEdgeInsets(layer.bounds, borders),
            LynxGetCornerInsets(layer.bounds, [_backgroundInfo borderRadius], borders));
      }
      const float inset = -3 * (MAX(shadow.blurRadius, 0) + MAX(shadow.spreadRadius, 0));
      const CGRect shadowOuterRect =
          CGRectOffset(CGRectInset(layer.bounds, inset, inset), shadow.offsetX, shadow.offsetY);
      CGPathAddRect(maskPath, nil, CGRectInset(CGRectUnion(layer.bounds, shadowOuterRect), -5, -5));

      if (!rasterizeShadow) {
        // clip area between outerRect and real shadow inner rect
        CAShapeLayer* shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.path = maskPath;
        shapeLayer.fillRule = kCAFillRuleEvenOdd;
        layer.mask = shapeLayer;
        layer.shadowPath = path;
      } else {
        [(LynxBoxShadowLayer*)layer setCustomShadowPath:path];
        [(LynxBoxShadowLayer*)layer setMaskPath:maskPath];
        layer.frame = shadowOuterRect;
        [(LynxBoxShadowLayer*)layer invalidate];
      }

      // always below border-layer, image layers, keep the order
      [self.backgroundLayer insertSublayer:layer atIndex:0];
      CGPathRelease(maskPath);
      CGPathRelease(path);
    }
  }
}

- (void)removeAssociateLayers {
  if (_borderLayer) {
    [_borderLayer removeFromSuperlayer];
  }
  if (_backgroundLayer) {
    [_backgroundLayer removeFromSuperlayer];
  }
}

- (void)setFilters:(nullable NSArray*)array {
  _backgroundLayer.filters = array;
  _borderLayer.filters = array;
  _outlineLayer.filters = array;
}

#pragma mark duplicate utils functions
+ (CGPathRef)createBezierPathWithRoundedRect:(CGRect)bounds
                                 borderRadii:(LynxBorderRadii)borderRadii
                                  edgeInsets:(UIEdgeInsets)edgeInsets {
  return [LynxBackgroundUtils createBezierPathWithRoundedRect:bounds
                                                  borderRadii:borderRadii
                                                   edgeInsets:edgeInsets];
}

+ (CGPathRef)createBezierPathWithRoundedRect:(CGRect)bounds
                                 borderRadii:(LynxBorderRadii)borderRadii {
  return [LynxBackgroundUtils createBezierPathWithRoundedRect:bounds borderRadii:borderRadii];
}

#pragma mark duplicate info functions
- (void)makeCssDefaultValueToFitW3c {
  [_backgroundInfo makeCssDefaultValueToFitW3c];
}

- (BOOL)hasDifferentBorderRadius {
  return [_backgroundInfo hasDifferentBorderRadius];
}

- (BOOL)hasDifferentBackgroundColor:(UIColor*)color {
  return _backgroundInfo.backgroundColor && _backgroundInfo.backgroundColor != color;
}

- (void)setBackgroundColor:(UIColor*)color {
  _backgroundColor = color;
  _backgroundInfo.backgroundColor = color;
}

- (void)setBorderRadius:(LynxBorderRadii)borderRadius {
  _isBorderChanged = YES;
  _borderRadius = borderRadius;
  [_backgroundInfo setBorderRadius:borderRadius];
}

- (void)setBorderWidth:(UIEdgeInsets)width {
  _borderWidth = width;
  [_backgroundInfo setBorderWidth:width];
}

- (void)setBorderTopColor:(UIColor*)borderTopColor {
  _borderTopColor = borderTopColor;
  [_backgroundInfo updateBorderColor:LynxBorderTop value:borderTopColor];
}

- (void)setBorderLeftColor:(UIColor*)borderLeftColor {
  _borderLeftColor = borderLeftColor;
  [_backgroundInfo updateBorderColor:LynxBorderLeft value:borderLeftColor];
}

- (void)setBorderRightColor:(UIColor*)borderRightColor {
  _borderRightColor = borderRightColor;
  [_backgroundInfo updateBorderColor:LynxBorderRight value:borderRightColor];
}

- (void)setBorderBottomColor:(UIColor*)borderBottomColor {
  _borderBottomColor = borderBottomColor;
  [_backgroundInfo updateBorderColor:LynxBorderBottom value:borderBottomColor];
}

- (BOOL)updateOutlineWidth:(CGFloat)outlineWidth {
  return [_backgroundInfo updateOutlineWidth:outlineWidth];
}

- (BOOL)updateOutlineColor:(UIColor*)outlineColor {
  return [_backgroundInfo updateOutlineColor:outlineColor];
}
- (BOOL)updateOutlineStyle:(LynxBorderStyle)outlineStyle {
  return [_backgroundInfo updateOutlineStyle:outlineStyle];
}

- (void)updateBorderColor:(LynxBorderPosition)position value:(UIColor*)color {
  [_backgroundInfo updateBorderColor:position value:color];
}

- (BOOL)updateBorderStyle:(LynxBorderPosition)position value:(LynxBorderStyle)style {
  return [_backgroundInfo updateBorderStyle:position value:style];
}
@end

@implementation LynxConverter (LynxBorderStyle)

+ (LynxBorderStyle)toLynxBorderStyle:(id)value {
  if (!value || [value isEqual:[NSNull null]]) {
    return LynxBorderStyleSolid;
  }
  return (LynxBorderStyle)[value intValue];
}
@end
