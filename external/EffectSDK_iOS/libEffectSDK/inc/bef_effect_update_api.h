#ifndef _BEF_EFFECT_UPDATE_API_H_
#define _BEF_EFFECT_UPDATE_API_H_

#include "bef_effect_public_define.h"

BEF_SDK_API void initUpdateManager(const char *rootDir, bool isDebugMode);
BEF_SDK_API void initRootDir(const char *rootDir);
BEF_SDK_API void clearCache(const char *rootDir);

#endif /*_BEF_EFFECT_UPDATE_API_H_*/