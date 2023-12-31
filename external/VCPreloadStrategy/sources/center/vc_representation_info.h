//
//  vc_representation_info.h

#ifndef vc_representation_info_hpp
#define vc_representation_info_hpp
#pragma once

#include "vc_base.h"
#include "vc_info.h"
#include "vc_json.h"

#include <string>
#include <vector>

VC_NAMESPACE_BEGIN

typedef std::vector<std::string> URLs;

class VCRepresentationInfo : public VCInfo {
public:
    typedef std::shared_ptr<VCRepresentationInfo> Ptr;

public:
    VCRepresentationInfo(VCInfoType type = VCInfoType::StreamInfo) :
            VCInfo(type){};
    ~VCRepresentationInfo() override;

public:
    int setStrValue(int key, const std::string &value) override;
    int setInt64Value(int key, int64_t value) override;
    int setIntValue(int key, int value) override;

    int64_t getInt64Value(int key, int64_t dValue = -1) const override;
    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const override;
    int getIntValue(int key, int dValue = -1) const override;

    void resetInfo() override;
    std::string toString() const override;
    void setUrls(std::shared_ptr<URLs> ulrs);
    std::shared_ptr<URLs> getUrlsPtr() const;
    URLs getUrls();

public:
    void setMdatOffset(int offset);

public:
    bool operator<(const VCRepresentationInfo &a) const {
        return (mFileHash.empty() || a.mFileHash.empty()) ?
                       (mFileId < a.mFileId) :
                       (mFileHash < a.mFileHash);
    }

    bool operator==(const VCRepresentationInfo &a) const {
        return (mFileHash.empty() || a.mFileHash.empty()) ?
                       (mFileId == a.mFileId) :
                       (mFileHash == a.mFileHash);
    }

public:
    std::string mMediaId;   // mediaId
    std::string mFileId;    // 用来标示Representation的ID
    std::string mMediaType; // 视频的码率信息。Enum{Video, Audio}
    int64_t mFileSize{0};   //视频的文件大小，单位Byte
    int mBitrate{0};        // MPD内的视频bandwidth，单位bps
    std::string mQuality; //当前视频的所选码率ladder。如“High_720P”
    int mWidth{0};        //视频码率的宽
    int mHeight{0};       //视频码率的高
    std::string mCodec;   //视频的编码标准
    std::string mFileHash;   //文件的 md5
    std::string mDefinition; //当前视频档位定义
    std::string mPCDNVerifyUrl;
    std::map<std::string, int64_t> mPreloadTimeGear;
    std::map<std::string, int64_t> mPreloadFrameGear;
    bool mIsAudio{false};
    int mResolutionIndex{0};

public:
    static Ptr RepInfo(const VCJson &info, const std::string &videoId);
    static VCString RepFileHash(const VCJson &info, VCStrCRef videoId);
    void toJsonValue(VCJson &jInfo);

protected:
    mutable std::mutex mMutex;
    std::shared_ptr<URLs> mUrls{nullptr};

private: /// run info
    int mMdatOffset{0};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCRepresentationInfo);
};

struct IVCRepInfoComparator {
    bool operator()(VCRepresentationInfo::Ptr const &left,
                    VCRepresentationInfo::Ptr const &right) const {
        return *left < *right;
    }
};

typedef std::map<VCRepresentationInfo::Ptr, int64_t, IVCRepInfoComparator>
        RepresentationPreloadMap;

VC_NAMESPACE_END

#endif /* vc_representation_info_hpp */
