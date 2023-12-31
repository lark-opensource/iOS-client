// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxKryptonEffectHandlerProtocol.h"

@class LynxTemplateRender;

enum {
  // style 0 - 1
  kFontStyleNormal = 0,
  kFontStyleItalic = 1,
  // weight 100 - 900
  kFontWeightNormal = 400,
  kFontWeightBold = 700,
};

@interface LynxKrypton : NSObject
+ (instancetype _Nonnull)shareInstance;
// localUrl: file:// assets:// or absolutePath
- (void)registerFontWithFamilyName:(nullable NSString *)familyName
                          localUrl:(nullable NSString *)localUrl
                            weight:(NSInteger)weight
                             style:(NSInteger)style;
@end

@protocol LynxKryptonHelper <NSObject>
- (void)setupWithTemplateRender:(nullable LynxTemplateRender *)templateRender;
- (void)registerService:(nullable Protocol *)protocol withImpl:(nullable id)serviceImpl;
- (void)setTemporaryDirectory:(nullable NSString *)directory;
- (void)setEffectHandler:(nullable id<LynxKryptonEffectHandlerProtocol>)handler;
@end
