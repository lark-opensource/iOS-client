#ifdef __cplusplus
//
// Created by wangyuanyuan on 2019/9/19.
//

#ifndef _VE_AUDIOPLAYER_FACTORY_H
#define _VE_AUDIOPLAYER_FACTORY_H

#include "AudioPlayerInterface.h"

using namespace  BEF;
class VEAudioPlayerFactory {
public:
    virtual ~VEAudioPlayerFactory(){}

    virtual AudioPlayerInterface *createAudioPlayer() {
        return nullptr;
    }

    virtual int destroyAudioPlayer(AudioPlayerInterface *instance) {
        return 0;
    }
    
    virtual void setBgmRecordLine(std::vector<bef_bgmRecordNode> &bgmRecordLine){
    }
};

#endif //_VE_AUDIOPLAYER_FACTORY_H

#endif