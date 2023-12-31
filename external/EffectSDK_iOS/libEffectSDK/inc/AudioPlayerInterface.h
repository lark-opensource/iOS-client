#ifdef __cplusplus
//
//  AudioPlayerInterace.h
//  effect-sdk
//
//  Created by youdong on 2017/8/30.
//  Copyright © 2017 youdong. All rights reserved.
//

#ifndef _EFFECT_AUDIO_PLAYER_INTERFACE_H_
#define _EFFECT_AUDIO_PLAYER_INTERFACE_H_

#include "bef_effect_public_business_define.h"
#include <string>

#define PLAYER_MESSAGE_TYPE_ENDPLAY 0x00000010

#define AUDIO_ALGORITHM_TYPE_3DAUDIO  0x00000001

namespace BEF {

class AudioPlayerInterface {
public:
    virtual ~AudioPlayerInterface() {}

    virtual int init() { return 0;}

    virtual int release() { return 0;}

    virtual void setDataSource(const std::string &strFilePath) = 0;
    
    virtual float getBgmLengthSeconds() { return 0;}

    virtual void startPlay() = 0;

    virtual void restartPlay() = 0;

    virtual void stopPlay() {}

    virtual void pause() = 0;

    virtual void resume() = 0;

    virtual bool isPlaying() = 0;

    virtual bool seek(float pos) { return false;}

    virtual void setLoop(int bLoop) {}

    virtual void setLoop(bool bLoop) {}

    virtual int getLoopCnt(void) { return 0;}

    virtual int getCurLoop(void) { return 0;}

    virtual void setCurLoopCount(int curLoopCount) {}

    virtual void setVolume(float volume) {}

    virtual void setIndex(int index) = 0;

    virtual int getIndex(void) = 0;

    virtual float getTotalPlayTime(void) = 0;

    virtual float getCurrentPlayTime(void) = 0;
    
    virtual void set3DAudioParam(bef_3Daudio_param parameter) { }
    
    virtual void audioAlgorithmConfig(int algorithmType, const char* config) {}
    
};

}

#endif /* _EFFECT_AUDIO_PLAYER_INTERFACE_H_ */

#endif