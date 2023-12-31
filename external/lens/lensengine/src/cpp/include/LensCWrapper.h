
// Copyright (C) 2020 Beijing Bytedance Network Technology Co., Ltd. All rights reserved.

#ifndef _LENS_C_WRAPPER_H_
#define _LENS_C_WRAPPER_H_

#ifdef _WIN32
#define LENS_EXPORT __declspec(dllexport)
#elif __APPLE__
#define LENS_EXPORT
#elif __ANDROID__
#define LENS_EXPORT __attribute__ ((visibility("default")))
#elif __linux__
#define LENS_EXPORT __attribute__ ((visibility("default")))
#endif

#include "LensEngine.h"

namespace LENS {
namespace FRAMEWORK {

extern "C" {
	LENS_EXPORT ILensEngineInterface* Create();

	LENS_EXPORT void Destory(ILensEngineInterface* enginePtr);

	LENS_EXPORT	const char* GetLensVersion();
}

} /* namespace FRAMEWORK */
} /* namespace LENS */

#endif //_LENS_C_WRAPPER_H_
