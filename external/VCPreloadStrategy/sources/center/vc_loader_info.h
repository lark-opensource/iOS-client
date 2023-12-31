//
//  ml_loader_info.hpp
//  VCPreloadStrategy
//
//  Created by 黄清 on 2020/10/12.
//

#ifndef ml_loader_info_hpp
#define ml_loader_info_hpp
#include "vc_base.h"
#include "vc_info.h"
#include "vc_shared_mutex.h"

#include <list>
#include <mutex>
#include <stdio.h>
#include <string>

VC_NAMESPACE_BEGIN

typedef enum : int {
    CDN = 0,
    P2P = 1,
} CDNType;

class VCRequestInfo : public VCInfo {
public:
    typedef std::shared_ptr<VCRequestInfo> Ptr;

    VCRequestInfo() : VCInfo(VCInfoType::RequestInfo){};
    ~VCRequestInfo() override = default;

public:
    inline bool operator==(const VCRequestInfo &o) {
        return mOff == o.mOff;
    }

public:
    void begin(int64_t rangeSize);
    void end(int64_t downloadOff);
    std::string toString() const override;
    void resetInfo() override;

public:
    typedef uint32_t DurationMS; // ms
    typedef uint64_t Timestamp;

    Timestamp mStartT{0};
    Timestamp mEndT{0};
    int64_t mOff{0};
    int64_t mSize{0};
    int64_t mDownloadSize{0};
    int mRtt{0};
    int mCdnType{CDNType::CDN}; // CDN类型 Enum{"CDN", "P2P"}
    int mIsHeader{0};           //当前Task是否是header。 Enum{true, false}
    DurationMS mTcpFirstPktD{0};
    DurationMS mHttpFirstPktD{0};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCRequestInfo);
};

typedef std::list<VCRequestInfo::Ptr> RequestInfoList;

class VCLoaderInfo : public VCInfo {
public:
    VCLoaderInfo() : VCInfo(VCInfoType::LoaderInfo){};
    ~VCLoaderInfo() override = default;

public:
    int setStrValue(int key, const std::string &value) override;
    int setInt64Value(int key, int64_t value) override;
    int setIntValue(int key, int value) override;

    int64_t getInt64Value(int key, int64_t dValue = -1) const override;
    int getIntValue(int key, int dValue = -1) const override;
    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const override;

public:
    // ret:nullable
    VCRequestInfo::Ptr getRequestInfo(int64_t off, bool needCreate = false);
    RequestInfoList getAllRequestInfo();

public:
    void resetInfo() override;
    std::string toString() const override;

private:
    void setDownloadOff(int64_t off);

private:
    std::string mCacheKey;    // loader info 的标识
    int mTaskStatus{0};       //
    int mDownloadType{0};     // current video, preload
    int64_t mDownloadSize{0}; // 已经下载的文件大小，单位Byte。
    int mTotalDownloadTimeMS{0}; //下载从开始到当前时刻的所过去的时间，单位ms。

    //
    std::string mMediaId;   // Loader正在下载的media_id
    std::string mFormat;    // Enum{"MP4", "DASH"}
    std::string mMediaType; // video or audio
    int mBitrate{0};        //当前task所选择的码率
    std::string mQuality;   //当前视频的质量，如“High_720P”.
    int64_t mFileSize{0};

    /// dash
    std::string mStreamId; //用来标示Representation的ID
    int mSegmentIndex{0}; //分片的序列递增唯一标识符。预加载报null。
    int64_t mSegmentTS{0}; //当前视频segment对应的timestamp。
    int64_t mByteStart{0}; // Task数据请求起始字节位置，单位Byte。Segment_offset
    int64_t mByteEnd{0}; // Task数据结束字节位置，单位Byte。
    float mSegmentDurationMS{0.0}; //分片的时长,单位ms。预加载报null。
    int64_t mStartTimeMS{0};       // Task被创建的时刻。

    /// request
    RequestInfoList mRequestInfo;
    static const size_t k_max_req_size = 30;

private:
    int64_t mMaxDownloadSize{0};
    int mDidAccessMDL{0};
    mutable shared_mutex mAccessMutex;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCLoaderInfo);
};

typedef std::list<std::shared_ptr<VCLoaderInfo>> LoaderInfoList;
typedef std::map<std::string, std::shared_ptr<VCLoaderInfo>> LoaderInfoMap;

VC_NAMESPACE_END

#endif /* ml_loader_info_hpp */
