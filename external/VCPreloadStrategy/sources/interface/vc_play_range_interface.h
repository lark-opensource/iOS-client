//
// Created by 黄清 on 2021/12/24.
//

#ifndef PRELOAD_VC_PLAY_RANGE_INTERFACE_H
#define PRELOAD_VC_PLAY_RANGE_INTERFACE_H
#pragma once

#include "vc_istrategy.h"

VC_NAMESPACE_BEGIN

class VCRangeParam : public IVCPrintable {
public:
    VCRangeParam() = default;

    ~VCRangeParam() override = default;

public:
    int64_t mOff{0};
    int64_t mSize{0};
    int64_t mContentRemainSize{0};
    int mDownloaderType{0};
    VCString mMediaId;
    VCString mFileHash;

public:
    std::string toString() const override {
        return "mediaId = " + mMediaId + ", fileHash = " + mFileHash +
               ", type = " + ToString(mDownloaderType) +
               ", off = " + ToString(mOff) + ", size = " + ToString(mSize);
    };

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCRangeParam);
};

class IVCPlayRange : public IVCStrategy {
public:
    typedef std::shared_ptr<IVCPlayRange> Ptr;

public:
    IVCPlayRange(VCStrCRef name) : IVCStrategy(VCModuleTypePlayRange, name){};

    ~IVCPlayRange() override = default;

public:
    virtual bool taskConcurrent() = 0;

    virtual void rangeSize(VCRangeParam &param) = 0;
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAY_RANGE_INTERFACE_H
