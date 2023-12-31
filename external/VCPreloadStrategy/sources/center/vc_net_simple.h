//
// Created by 黄清 on 2021/9/29.
//

#ifndef PRELOAD_VC_NET_SIMPLE_H
#define PRELOAD_VC_NET_SIMPLE_H

#include "vc_info.h"
#pragma once

VC_NAMESPACE_BEGIN

class VCNetSimple : public VCInfo {
public:
    typedef std::shared_ptr<VCNetSimple> Ptr;

public:
    VCNetSimple();
    ~VCNetSimple() override;

public:
    void resetInfo() override;

public:
    inline bool operator<(const VCNetSimple &o) const {
        return this->mSpeedInbPS < o.mSpeedInbPS;
    }

public:
    std::string toString() const override;

public:
    VCString mMediaId;
    std::string mStreamId; // rep.fileHash
    int mTrackType{0};
    uint64_t mBytes{0};
    int64_t mTime{0};
    int64_t mTimestamp{-1};
    int64_t mRtt{0};
    int64_t mLastDataRecv{0};
    double mSpeedInbPS{-1.0f};  //每秒多少字bit
    std::string mMdlLoaderType; // HTTP or PCDN loader

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCNetSimple);
};

VC_NAMESPACE_END
#endif // PRELOAD_VC_NET_SIMPLE_H
