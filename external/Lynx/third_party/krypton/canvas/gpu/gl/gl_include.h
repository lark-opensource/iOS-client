// Copyright (c) 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_GL_INCLUDE_H_
#define CANVAS_GPU_GL_GL_INCLUDE_H_

// clang-format off
#ifdef OS_ANDROID
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <GLES2/gl2ext.h>
#include <GLES3/gl3ext.h>
#include <GLES3/gl3platform.h>
#elif OS_IOS
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES2/glext.h>
#elif defined(OS_WIN) || defined(OS_OSX)
#include "third_party/angle/include/angle_gl.h"
#else
#include "third_party/khronos/GLES3/gl3.h"
#include "third_party/khronos/GLES2/gl2ext.h"
#endif
// clang-format on

#endif  // CANVAS_GPU_GL_GL_INCLUDE_H_
