#ifdef __cplusplus
/**
* @file VEVideoPlayerFactory.h
* @author jj.shergill (jj.shergill@bytedance.com)
* @brief VEVideoPlayerFactory for implementation through bef_effect_api
* @version 0.1
* @date 2023-02-07
* @copyright Copyright (c) 2023
 */
#pragma once

#include "VideoPlayerInterface.h"
#include <string>

using namespace BEF;

/**
 * @brief VE VideoPlayer Factory Interface.
 */
class VEVideoPlayerFactory {
public:
    /**
     * @brief Destroy the Video Player Factory
     */
    virtual ~VEVideoPlayerFactory(){}

    /**
     * @brief Create a video player factory with a set key
     */
    virtual VideoPlayerInterface *createVideoPlayer(const std::string &key) {
        return nullptr;
    }

    /**
     * @brief Destroy a video player instance
     */
    virtual int destroyVideoPlayer(VideoPlayerInterface *instance) {
        return 0;
    }

    /**
     * @brief Get the max number of video players that is supported on a device
     */
    virtual int getMaxVideoPlayers() {
        return 0;
    }
};

#endif