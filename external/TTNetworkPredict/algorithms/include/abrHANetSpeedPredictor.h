//
// Created by xuzhimin on 2020-03-19.
//

#ifndef ABR_ABRHANETSPEEDPREDICTOR_H
#define ABR_ABRHANETSPEEDPREDICTOR_H
#include "INetworkSpeedPredictor.h"
#include "abrBaseSpeedPredictor.h"
#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include "network_speed_predictor_key.h"
#include "network_speed_pedictor_base.h"
#include "algorithmCommon.h"
#include <vector>
#include <inttypes.h>
#include <map>

NETWORKPREDICT_NAMESPACE_BEGIN

class abrHANetSpeedPredictor: public abrBaseSpeedPredictor {
public:
    abrHANetSpeedPredictor();
    ~abrHANetSpeedPredictor();

    float predictBandwidth(int media_type) override;

    void predictMultiBandwidth();
    int findStreamIndex(std::string stream_id, int media_type);
    int findStreamFailedIndex(int media_type);
    int findLoadTypeIndex(std::string load_type, int media_type);
    int findLoadTypeFailedIndex(int media_type);
    void updateStreamBandwidthInfo(std::string stream_id, float stream_download_speed, int64_t timestamp_start, int64_t timestamp_end, int media_type);
    void updateLoadTypeBandwidthInfo(std::string load_type, float load_type_download_speed, int64_t timestamp_start, int64_t timestamp_end, int media_type);
private:
    int mStreamSlidingWindowSize;
    int mLoadTypeSlidingWindowSize;
    std::vector<StreamMediaBandwidthInfo> mRecentStreamVideoBandwidthInfo;
    std::vector<StreamMediaBandwidthInfo> mRecentStreamAudioBandwidthInfo;
    std::vector<LoadTypeMediaBandwidthInfo> mRecentLoadTypeVideoBandwidthInfo;
    std::vector<LoadTypeMediaBandwidthInfo> mRecentLoadTypeAudioBandwidthInfo;
};

NETWORKPREDICT_NAMESPACE_END
#endif //ABR_ABRHANETSPEEDPREDICTOR_H
