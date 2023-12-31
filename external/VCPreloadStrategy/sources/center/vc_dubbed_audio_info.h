//
//  vc_dubbed_audio_info.h
//  zhongzhendong 2022.08.04
//

#ifndef vc_dubbed_info_hpp
#define vc_dubbed_info_hpp
#pragma once

#include "vc_base.h"
#include "vc_info.h"
#include "vc_json.h"
#include "vc_representation_info.h"

#include <string>
#include <vector>

VC_NAMESPACE_BEGIN

typedef std::vector<std::string> URLs;

class VCDubbedAudioInfo : public VCRepresentationInfo {
public:
    typedef std::shared_ptr<VCDubbedAudioInfo> Ptr;

public:
    VCDubbedAudioInfo() : VCRepresentationInfo(VCInfoType::DubbedInfo){};
    ~VCDubbedAudioInfo() override;

public:
    void resetInfo() override;
    std::string toString() const override;

public:
    bool operator<(const VCDubbedAudioInfo &a) const {
        return (mInfoId.empty() || a.mInfoId.empty()) ?
                       (mInfoId < a.mInfoId) :
                       (mFileHash < a.mFileHash);
    }

    bool operator==(const VCDubbedAudioInfo &a) const {
        return (mInfoId.empty() || a.mInfoId.empty()) ?
                       (mInfoId == a.mInfoId) :
                       (mFileHash == a.mFileHash);
    }

public:
    std::string mMediaId;
    std::string mInfoId; // infoId 用来标示 VCDubbedAudioInfo 的ID
    std::string mId;

public:
    static VCString DubbedInfoId(const VCJson &info, VCStrCRef videoId);
    static Ptr DubbedInfo(const VCJson &info, const std::string &videoId);
    void toJsonValue(VCJson &jInfo);

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCDubbedAudioInfo);
};

struct IVCDubbedInfoComparator {
    bool operator()(VCDubbedAudioInfo::Ptr const &left,
                    VCDubbedAudioInfo::Ptr const &right) const {
        return *left < *right;
    }
};

typedef std::map<VCDubbedAudioInfo::Ptr, int64_t, IVCDubbedInfoComparator>
        DubbedInfoPreloadMap;

VC_NAMESPACE_END

#endif /* vc_dubbed_info_hpp */