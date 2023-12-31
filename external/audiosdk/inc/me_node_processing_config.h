//
// Created by LIJING on 2022/4/6.
//

#pragma once
#ifndef SAMI_CORE_ME_NODE_PROCESSING_CONFIG_H
#define SAMI_CORE_ME_NODE_PROCESSING_CONFIG_H

#include "mammon_engine_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

typedef struct
{
    size_t sample_rate;
    size_t max_block_size;
} NodeProcessingConfig;

MAMMON_ENGINE_NAMESPACE_END

#endif  //SAMI_CORE_ME_NODE_PROCESSING_CONFIG_H
