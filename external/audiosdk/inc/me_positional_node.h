//
// Created by shidephen on 2020/5/11.
//

#ifndef MAMMONSDK_ME_POSITIONAL_NODE_H
#define MAMMONSDK_ME_POSITIONAL_NODE_H

#include "mammon_engine_type_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * Triggered at a specific time.
 */
class MAMMON_EXPORT PositionalNode {
public:
    /**
     * Start at time
     * @param time time to start
     */
    virtual void startAtTime(TransportTime time) = 0;
    /**
     * Stop at time
     * @param time time to stop
     */
    virtual void stopAtTime(TransportTime time) = 0;
};
MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_ME_POSITIONAL_NODE_H
