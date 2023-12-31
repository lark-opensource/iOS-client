//
// Created by 黄清 on 12/17/20.
//

#ifndef VIDEOENGINE_VC_LOADER_INFO_SET_H
#define VIDEOENGINE_VC_LOADER_INFO_SET_H
#pragma once
#include <memory>
#include <mutex>

#include "vc_loader_info.h"
#include "vc_shared_mutex.h"

VC_NAMESPACE_BEGIN

/// MARK: - Class VCLoaderInfoHandler

class VCLoaderInfoHandler {
public:
    VCLoaderInfoHandler();
    ~VCLoaderInfoHandler();

public:
    std::shared_ptr<VCLoaderInfo> getLoaderInfo(const std::string &fileHash);
    void addLoaderInfo(std::shared_ptr<VCLoaderInfo> &info);
    void removeLoaderInfo(const std::string &fileHash);
    LoaderInfoList getAllLoaderInfo();
    // void clearLoaderInfo(void);
    int size();

public:
    void setMaxCacheSize(int cacheSize);
    int getMaxCacheSize();

public:
    static const int k_max_size = 30;

private:
    int mMaxCacheSize{k_max_size};
    LoaderInfoList mLoaderInfos;
    LoaderInfoMap mLoaderInfoMap;
    shared_mutex mLoaderInfoMutex;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCLoaderInfoHandler);
};

VC_NAMESPACE_END
#endif // VIDEOENGINE_VC_LOADER_INFO_SET_H
