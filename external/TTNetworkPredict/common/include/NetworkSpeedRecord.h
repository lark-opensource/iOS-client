//
// Created by guikunzhi on 2020-03-13.
//

#ifndef SPEEDRECORD_H
#define SPEEDRECORD_H

#include <stdint.h>
#include <string>
#include <vector>
#include <memory>
#include "network_speed_pedictor_base.h"

NETWORKPREDICT_NAMESPACE_BEGIN
class SpeedRecordOld;
class SpeedRecordItem {
public:
    SpeedRecordItem(int trackType, int64_t bytes, int64_t time, int64_t timestamp,
                    std::string loadType, std::string host, int64_t tcpRtt, int64_t lastDataRecv,
                    std::string mdlLoaderType, int64_t s_off, int64_t e_off, int64_t cbs, int64_t fbs);
    SpeedRecordItem(const std::shared_ptr<SpeedRecordOld>& speedRecord);
    SpeedRecordItem();
    ~SpeedRecordItem();
public:
    int trackType;
    uint64_t bytes;  // Byte
    int64_t time;  // ms
    int64_t timestamp;  //ms
    std::string loadType;
    std::string host;
    int64_t  tcpRtt;
    int64_t lastDataRecv;
    std::string mdlLoaderType; // HTTP or PCDN loader
    int64_t s_off; // range start offset
    int64_t e_off; // range end offset
    int64_t cbs; // current mdl buffer size
    int64_t fbs; // full mdl buffer size
};

class SpeedRecord {
public:
    SpeedRecord();
    ~SpeedRecord();
public:
    std::string streamId;
    std::vector<std::shared_ptr<SpeedRecordItem>> speedRecords;
};

class SpeedRecordOld {
    public:
        SpeedRecordOld();
        ~SpeedRecordOld();

    public:
        std::string streamId;
        int trackType;
        uint64_t bytes;
        int64_t time;
        int64_t timestamp;
        int64_t rtt;
        int64_t lastDataRecv;
        double speedInbPS; //每秒多少字bit
        std::string mdlLoaderType; // HTTP or PCDN loader
        int64_t s_off; // range start offset
        int64_t e_off; // range end offset
        int64_t cbs; // current mdl buffer size
        int64_t fbs; // full mdl buffer size
};

NETWORKPREDICT_NAMESPACE_END

#endif //ABR_SPEEDRECORD_H
