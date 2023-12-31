#ifdef __cplusplus
/**
* @file VideoPlayerInterface.h
* @author jj.shergill (jj.shergill@bytedance.com)
* @brief VideoPlayerInterface for implementation through bef_effect_api
* @version 0.1
* @date 2023-02-07
* @copyright Copyright (c) 2023
 */
#pragma once

#include <string>

namespace BEF {
/**
 * @brief Video Player State.
 */
enum class VideoPlayerState {
    Playing,
    Paused,
    Err
};

/**
 * @brief Video Player Interface.
 */
class VideoPlayerInterface {
public:
    /**
     * @brief Destroy the Video Player
     */
    virtual ~VideoPlayerInterface() {}

    /**
     * @brief Initialize the Video Player, video is ready to play after this, source must be set first.
     */
    virtual int init() { return 0; }

    /**
     * @brief Release the Video Player and video file source.
     */
    virtual int release() { return 0; }

    /**
     * @brief Set the video file source.
     */
    virtual int setVideoSource(const std::string &strFilePath) = 0;

    /**
     * @brief Get the video file source.
     */
    virtual std::string getVideoSource(void) = 0;

    /**
     * @brief Start playing the video.
     */
    virtual void play() = 0;

    /**
     * @brief Pause the video.
     */
    virtual void pause() = 0;

    /**
     * @brief Resume playing the video.
     */
    virtual void resume() = 0;

    /**
     * @brief Get the Player State.
     */
    virtual VideoPlayerState getState() = 0;

    /**
     * @brief Get the current frame from the video.
     */
    virtual void* getFrame(float deltaTime) { return nullptr; }

    /**
     * @brief Set if loop forever.
     */
    virtual void setLoop(bool bLoop) = 0;

    /**
     * @brief Get if loop forever.
     */
    virtual bool getLoop() = 0;

    /**
     * @brief Set volume level.
     */
    virtual void setVolume(float volume) {}

    /**
     * @brief Get volume level.
     */
    virtual float getVolume(void) { return 0; }

    /**
     * @brief Move video based on position.
     */
    virtual bool seek(int64_t pos) = 0;

    /**
     * @brief Get current video position.
     */
    virtual int64_t getPosition(void) = 0;

    /**
     * @brief Get current video speed.
     */
    virtual float getSpeed() { return 0; }

    /**
     * @brief Set video position.
     */
    virtual void setSpeed(float speed) {  }

    /**
     * @brief Get length of video.
     */
    virtual int64_t getLength() = 0;
};
}

#endif