//
// Created by Yi Zhang on 2023/4/20.
//

#ifndef bef_swing_async_define_h
#define bef_swing_async_define_h
#pragma once

#include "bef_framework_public_base_define.h"

/**
 *@brief Currently, not all resources are created from Loading Thread but also Main Thread(Rendering), while new Objects are all collected by ResourceManager globally.
 * This will make rendering & syncResource without thread security, Such as Material, both will invoke `getInstantiatedMaterial` or `isGood` at the same time.
 * Currently keep object interface thread-safe is boring and expensive, so we use classifier(TLS thread-id) to distinguish them.
 */
enum ResourceClassifier
{
    WITH_DEFAULT        = 0,//no different for all

    WITH_THREAD_MAIN    = 1,
    WITH_THREAD_SUB     = 1<<1,
    WITH_THREAD_SUB1    = 1<<2,
    WITH_THREAD_SUB2    = 1<<3,
    WITH_THREAD_SUB3    = 1<<4,

    WITH_WORKER         = 1<<8,
    WITH_WORKER1        = 1<<9,
    WITH_WORKER2        = 1<<10,
    WITH_WORKER3        = 1<<11,
};
typedef enum ResourceClassifier resource_classifier;

/**
 * @brief classifier retriever, usually set by user.
 * it must be thread-safe.
 */
typedef resource_classifier(*FuncClassifierRetriever)(void* userdata);

#endif //bef_swing_async_define_h
