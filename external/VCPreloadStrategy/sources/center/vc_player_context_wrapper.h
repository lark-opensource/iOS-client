//
// Created by 黄清 on 2022/9/3.
//

#ifndef PRELOAD_VC_PLAYER_CONTEXT_WRAPPER_H
#define PRELOAD_VC_PLAYER_CONTEXT_WRAPPER_H
#pragma once

#include "av_player_interface.h"
#include "vc_base.h"

USE_PEV_NAMESPACE;

VC_NAMESPACE_BEGIN

class VCManager;

class VCPlayerContextWrapper : public IContextInfo {
public:
    VCPlayerContextWrapper() = default;
    ~VCPlayerContextWrapper() override = default;

public:
    void embedContext(VCManager *context);

public:
    int64_t getCacheInfo(void *fileKey, int key, int64_t dVal) override;

    int64_t getInt64Value(int key, int64_t dVal) override;
    int64_t getInt64Value(IPlayer *player, int key, int64_t dVal) override;

    int getIntValue(int key, int dVal) override;
    int getIntValue(IPlayer *player, int key, int dVal) override;

    double getDoubleValue(int key, double dVal) override;
    double getDoubleValue(IPlayer *player, int key, double dVal) override;

    char *getCStringValue(int key, char *dVal) override;
    char *getCStringValue(IPlayer *player, int key, char *dVal) override;

private:
    VCManager *mContext{nullptr};
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAYER_CONTEXT_WRAPPER_H
