//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "BDXLynxBlurEffect.h"
#import <objc/runtime.h>

@interface BDXLynxBlurEffect ()
@property(nonatomic, assign) CGFloat blurRadius;
@end

@implementation BDXLynxBlurEffect
+ (UIBlurEffect* _Nullable)effectWithStyle:(UIBlurEffectStyle)style
                                blurRadius:(CGFloat)radius {
  UIBlurEffect* effect = [BDXLynxBlurEffect effectWithStyle:style];
  if ([effect isKindOfClass:[BDXLynxBlurEffect class]]) {
    BDXLynxBlurEffect* blurEffect = (BDXLynxBlurEffect*)effect;
    blurEffect.blurRadius = radius;
  }
  return effect;
}

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self customBlurConfig];
  });
}

+ (void)customBlurConfig {
  // UIBlurEffect get blur settings via method '- (id)effectSettings'. The
  // return value contains configs for the effect.
  SEL effectSettings = NSSelectorFromString(@"effectSettings");
  if (![self instancesRespondToSelector:effectSettings]) {
    return;
  }

  __block id (*func)(id, SEL) = NULL;
  // clang-format off
  // Following is the customized implementation of method 'effectSettings'.
  // 1. create the config instance via original implementation.
  // 2. iterate ivar list and modify the '_blurRadius' field if exists.
  // 3. return the objects.
  // clang-format on
  IMP imp = imp_implementationWithBlock(^id(UIBlurEffect* effect) {
    id config = nil;
    // call the original effectSettings.
    if (func) {
      config = func(effect, effectSettings);
    }

    if ([effect isKindOfClass:BDXLynxBlurEffect.class]) {
      BDXLynxBlurEffect* blurEffect = (BDXLynxBlurEffect*)effect;
      Class cls = [config class];
      while (cls && cls != [NSObject class]) {
        unsigned int uVarCount = 0;
        Ivar* pVarList = class_copyIvarList(cls, &uVarCount);
        for (unsigned int i = 0; i < uVarCount; ++i) {
          Ivar pVar = pVarList[i];
          const char* varName = ivar_getName(pVar);
          NSString* strVarName = [NSString stringWithUTF8String:varName];
          double* configIvarPtr =
              (double*)((uint8_t*)(long)config + ivar_getOffset(pVar));
          if ([strVarName isEqualToString:@"_blurRadius"] &&
              blurEffect.blurRadius > 0) {
            *configIvarPtr = blurEffect.blurRadius;
          }
        }
        if (pVarList) {
          free(pVarList);
          pVarList = NULL;
        }
        // find instance variables held by superclass
        cls = class_getSuperclass(cls);
      }
    }
    return config;
  });

  Method method = class_getInstanceMethod(self, effectSettings);
  // Save the original implementation of 'effectSettings'.
  func = (id(*)(id, SEL))method_getImplementation(method);
  // Set customized implementation to enable blur radius modification.
  method_setImplementation(method, imp);
}
@end
