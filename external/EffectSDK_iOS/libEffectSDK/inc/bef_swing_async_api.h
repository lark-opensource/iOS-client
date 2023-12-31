//
// Created by Yi Zhang on 2023/4/20.
//

#ifndef bef_swing_async_api_h
#define bef_swing_async_api_h
#pragma once

#include "bef_swing_async_define.h"
#include "bef_swing_define.h"

/**
 * will be removed as it will done by engine itself.
 * only collect and process material from:
 * MacOS: `WITH_THREAD_SUB`(glAsyncProcessQueue) thread
 * Windows: ...
 *
 * MainThread(seek_frame)      ===>  ResourceClassifier::WITH_THREAD_MAIN
 * LoadThread(create_segment)  ===>  ResourceClassifier::WITH_THREAD_SUB
 */
BEF_SDK_API bef_effect_result_t
bef_swing_async_set_classifier_retriever(bef_swing_manager_t* managerHandle,
                                        FuncClassifierRetriever func, void* userdata);

BEF_SDK_API bef_effect_result_t
bef_swing_async_set_classifier_mask(bef_swing_manager_t* managerHandle,
                                    int32_t mask);

#endif //bef_swing_async_api_h
