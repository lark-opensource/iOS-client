//
// Created by xuzhimin on 2020-03-20.
//

#include "abrLSTMNetSpeedPredictor.h"

NETWORKPREDICT_NAMESPACE_BEGIN

abrLSTMNetSpeedPredictor::abrLSTMNetSpeedPredictor()
{
}

abrLSTMNetSpeedPredictor::~abrLSTMNetSpeedPredictor() {
}

float abrLSTMNetSpeedPredictor::predictBandwidth(int media_type) {
    float predicted_bandwidth = 0.0;
    if (media_type == VIDEO_TYPE) {
        //To do ......
    } else if (media_type == AUDIO_TYPE) {
        //To do ......
    } else {
        //pass
    }
    LOGD("[SelectorLog] [LSTMNet] predicted_bandwidth=%f", predicted_bandwidth);
    return predicted_bandwidth;
}

NETWORKPREDICT_NAMESPACE_END
