/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <malloc/malloc.h>

@class FBObjectGraphConfiguration;
@class FBObjectiveCGraphElement;

#ifdef __cplusplus
extern "C" {
#endif

/**
 Wrapper functions, for given object they will categorize it and create proper Graph Element subclass instance
 for it.
 */
FBObjectiveCGraphElement *_Nullable FBWrapObjectGraphElementWithContext(FBObjectiveCGraphElement *_Nullable sourceElement,
                                                                        id _Nullable object,
                                                                        FBObjectGraphConfiguration *_Nullable configuration,
                                                                        NSArray<NSString *> *_Nullable namePath);
FBObjectiveCGraphElement *_Nullable FBWrapObjectGraphElement(FBObjectiveCGraphElement *_Nullable sourceElement,
                                                             id _Nullable object,
                                                             FBObjectGraphConfiguration *_Nullable configuration);

/*
 xushuangqing 有些私有对象，比如 _PFResultASCIIString，在被 weak 持有时会 crash，这些对象并不是 malloc 出来的，所以用 malloc_zone_from_ptr 过滤掉这些对象 https://bytedance.feishu.cn/docs/doccnHPW3RI8hlDwaR7SmXvQoWe
 
 huangchengzhi iOS 16，NSMapTable 的 key 可能会为 -1 ，在被转换为指针时会变成 0xffffffffffffffff，而 iOS 16 上将 -1 传入 malloc_zone_from_ptr() 会发生崩溃，提前保护。原因还在分析中，后续进度更新于：https://bytedance.feishu.cn/docx/doxcnXcoUFBMiy4qJLF9v8k1iKf
 }
 */
malloc_zone_t *fb_safe_malloc_zone_from_ptr(const void *ptr);

#ifdef __cplusplus
}
#endif
