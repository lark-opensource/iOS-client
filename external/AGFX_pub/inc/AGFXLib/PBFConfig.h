//
//  config.h
//  Pods
//
//  Created by fanwenjie.tiktok on 2019/6/18.
//

#ifndef config_h
#define config_h

#undef SHADER_GL
#undef SHADER_GLES31
#undef SHADER_VULKAN
#undef SHADER_METAL

//#include "RendererDeviceInternal.h"
#ifdef NDEBUG
#undef NDEBUG
#endif
#define NDEBUG 1

//#define SHADER_FROM_BYTECODE

// choose different shader according to the platform
#if AMAZING_PLATFORM == AMAZING_ANDROID
#define getShaderString(_name) _name##_es31
#elif AMAZING_PLATFORM == AMAZING_IOS || AMAZING_PLATFORM == AMAZING_MACOS
#define getShaderString(_name) _name##_metal
#else
#define getShaderString(_name) _name##_es31
#endif

#if AMAZING_PLATFORM == AMAZING_ANDROID
#define __WIDTH 1080
#define __HEIGHT 1680
#elif AMAZING_PLATFORM == AMAZING_IOS
#define __WIDTH 720
#define __HEIGHT 1280
#else
#define __WIDTH 1920
#define __HEIGHT 1080
#endif

#endif /* config_h */
