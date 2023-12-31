#ifdef __cplusplus
//
// Created by lizhiqi on 2019/4/19.
//

#ifndef ANDROIDDEMO_LIVEAUDIOPLAYER_H
#define ANDROIDDEMO_LIVEAUDIOPLAYER_H

#include "AudioPlayerInterface.h"

using namespace  BEF;
class LiveAudioPlayerFactory {
public:
    virtual ~LiveAudioPlayerFactory(){}

    virtual AudioPlayerInterface *createAudioPlayer() {
        return nullptr;
    }

    virtual int destroyAudioPlayer(AudioPlayerInterface *instance) {
        return 0;
    }
};

#endif //ANDROIDDEMO_LIVEAUDIOPLAYER_H

#endif