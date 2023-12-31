//
// Created by guikunzhi on 2020-03-13.
//

#include "NetworkSpeedRecord.h"

#include <utility>

NETWORKPREDICT_NAMESPACE_BEGIN

SpeedRecordItem::SpeedRecordItem(int trackType, int64_t bytes, int64_t time, int64_t timestamp,
                                 std::string loadType, std::string host, int64_t tcpRtt, int64_t lastDataRecv,
                                 std::string mdlLoaderType, int64_t s_off, int64_t e_off, int64_t cbs, int64_t fbs)
                                 :trackType(trackType)
                                 ,bytes(bytes)
                                 ,time(time)
                                 ,timestamp(timestamp)
                                 ,loadType(std::move(loadType))
                                 ,host(std::move(host))
                                 ,tcpRtt(tcpRtt)
                                 ,lastDataRecv(lastDataRecv)
                                 ,mdlLoaderType(std::move(mdlLoaderType))
                                 ,s_off(s_off)
                                 ,e_off(e_off)
                                 ,cbs(cbs)
                                 ,fbs(fbs)
                                 {

}

SpeedRecordItem::SpeedRecordItem(const std::shared_ptr<SpeedRecordOld>& speedRecord){
    if (!speedRecord)
        return;
    this->trackType = speedRecord->trackType;
    this->bytes = speedRecord->bytes;
    this->time = speedRecord->time;
    this->timestamp = speedRecord->timestamp;
    this->loadType = "unknown";
    this->host = "-1";
    this->tcpRtt = speedRecord->rtt;
    this->lastDataRecv = speedRecord->lastDataRecv;
    this->mdlLoaderType = speedRecord->mdlLoaderType;
    this->s_off = speedRecord->s_off;
    this->e_off = speedRecord->e_off;
    this->cbs = speedRecord->cbs;
    this->fbs = speedRecord->fbs;
}

SpeedRecordItem::SpeedRecordItem():trackType(-1),bytes(-1),time(-1),timestamp(-1),loadType(""),host(""),tcpRtt(-1),
lastDataRecv(-1), mdlLoaderType(""), s_off(-1), e_off(-1), cbs(-1), fbs(-1){

}

SpeedRecordItem::~SpeedRecordItem() {}


SpeedRecord::SpeedRecord() {}

SpeedRecord::~SpeedRecord() {
}

SpeedRecordOld::SpeedRecordOld()
:trackType(-1)
,bytes(-1)
,time(-1)
,timestamp(-1)
,rtt(-1)
,lastDataRecv(-1)
,speedInbPS(-1)
,mdlLoaderType("")
,s_off(-1)
,e_off(-1)
,cbs(-1)
,fbs(-1)
{}

SpeedRecordOld::~SpeedRecordOld() {
}

NETWORKPREDICT_NAMESPACE_END
