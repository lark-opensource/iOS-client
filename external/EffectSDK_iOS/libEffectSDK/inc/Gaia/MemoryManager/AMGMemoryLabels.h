/**
 * @file AMGMemoryLabels.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The Defination of memory labels.
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#pragma once

#ifndef AMG_ALLOCATOR_LABELS_H
#define AMG_ALLOCATOR_LABELS_H

#include "Gaia/AMGExport.h"

/**
 * @brief The enum of memory labels.
 * 
 */
enum AMGMemLabelIdentifier
{
#define AMG_DO_LABEL(Name) Name,
#include "Gaia/MemoryManager/AMGMemoryLabelNames.h"
#undef AMG_DO_LABEL
    LabelCount
};

/**
 * @brief Get the name of memory label.
 * 
 * @param memLabel The memory identifier.
 * @return const char* The name of memory label.
 */
GAIA_LIB_EXPORT const char* GetMemLabelName(AMGMemLabelIdentifier memLabel);
#endif
