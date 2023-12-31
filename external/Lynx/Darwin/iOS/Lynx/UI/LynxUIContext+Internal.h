// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxUIContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUIContext ()

- (void)setDefaultOverflowVisible:(BOOL)enable;
- (void)setDefaultImplicitAnimation:(BOOL)enable;
- (void)setEnableTextRefactor:(BOOL)enable;
- (void)setEnableTextOverflow:(BOOL)enable;
- (void)setEnableNewClipMode:(BOOL)enable;
- (void)setEnableEventRefactor:(BOOL)enable;
- (void)setEnableA11yIDMutationObserver:(BOOL)enable;
- (void)setEnableEventThrough:(BOOL)enable;
- (void)setEnableBackgroundShapeLayer:(BOOL)enable;
- (void)setEnableFiberArch:(BOOL)enable;
- (void)setEnableExposureUIMargin:(BOOL)enable;
- (void)setEnableTextLanguageAlignment:(BOOL)enable;
- (void)setEnableXTextLayoutReused:(BOOL)enable;
- (void)setTargetSdkVersion:(NSString*)version;

@end

NS_ASSUME_NONNULL_END
