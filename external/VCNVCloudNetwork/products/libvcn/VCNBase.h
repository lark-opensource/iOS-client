/*
 * MediaLoader
 *
 * Author:taohaiqing(taohaiqing@bytedance.com)
 * Date:2022-06-28
 * Copyright (c) 2022 bytedance

 * This file is part of VCN.
 *
 */
#pragma once
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#ifdef __cplusplus
#define NS_VCN_BEGIN namespace com{ namespace ss{ namespace mediakit{ namespace vcn{
#define NS_VCN_END  }}}}
#define NS_VCN_CLASS(a) namespace com{ namespace ss{ namespace mediakit{ namespace vcn{class a;}}}}
#define USING_VCN_NS using namespace com::ss::mediakit::vcn;

#else
#define NS_VCN_BEGIN
#define NS_VCN_END
#define USING_VCN_NS

#endif
#define VCN_INTERFACE_EXPORT __attribute__((visibility ("default")))

