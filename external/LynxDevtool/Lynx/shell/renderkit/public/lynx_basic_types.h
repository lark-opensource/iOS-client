// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_BASIC_TYPES_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_BASIC_TYPES_H_
namespace lynx {
/**
 * This enum is used to define size measure mode of LynxView.
 * If mode is Undefined, the size will be determined by the content.
 * If mode is Exact, the size will be the size set by outside.
 * If mode is Max, the size will be determined by the content, but not exceed
 * the maximum size.
 */
enum LynxViewBaseSizeMode {
  LynxViewBaseSizeModeUndefined = 0,
  LynxViewBaseSizeModeExact,
  LynxViewBaseSizeModeMax
};

enum LynxThreadStrategyForRender {
  LynxThreadStrategyForRenderAllOnUI = 0,
  LynxThreadStrategyForRenderMostOnTASM = 1,
  LynxThreadStrategyForRenderPartOnLayout = 2,
  LynxThreadStrategyForRenderMultiThreads = 3,
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_BASIC_TYPES_H_
