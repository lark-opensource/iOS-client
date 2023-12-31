/*
 * MediaLoader
 *
 * Author:taohaiqing(taohaiqing@bytedance.com)
 * Date:2018-10-23
 * Copyright (c) 2018 bytedance
 
 * This file is part of MediaLoader.
 *
 */
#pragma once
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#ifdef __cplusplus
#define NS_MEDIALOADER_BEGIN namespace com{ namespace ss{ namespace ttm{ namespace medialoader{
#define NS_MEDIALOADER_END  }}}}
#define NS_MEDIALOADER_CLASS(a) namespace com{ namespace ss{ namespace ttm{ namespace medialoader{class a;}}}}
#define USING_MEDIALOADER_NS using namespace com::ss::ttm::medialoader;

#else
#define NS_MEDIALOADER_BEGIN
#define NS_MEDIALOADER_END
#define USING_MEDIALOADER_NS

#endif

