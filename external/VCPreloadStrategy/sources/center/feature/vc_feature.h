//
// Created by 黄清 on 2022/9/4.
//

#ifndef PRELOAD_VC_FEATURE_H
#define PRELOAD_VC_FEATURE_H

#pragma once

#include "vc_feature_define.h"
#include "vc_object.h"

VC_NAMESPACE_BEGIN

class VCFeature : public IVCPrintable {
public:
    typedef std::shared_ptr<VCFeature> Ptr;
    VCFeature() = default;
    ~VCFeature() override = default;

public:
    VCFeatureType mType{VCFeatureTypeKV};
    VCString mName;
    VCString mGroup;
    VCString mSessionId;

public:
    std::string toString() const override;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCFeature);
};

class VCKVFeature : public VCFeature {
public:
    typedef std::shared_ptr<VCKVFeature> Ptr;
    VCKVFeature(VCStrCRef name, const std::shared_ptr<Object> &obj);
    ~VCKVFeature() override = default;

public:
    std::shared_ptr<Object> getValue() {
        return mValue;
    }

public:
    std::string toString() const override;

private:
    std::shared_ptr<Object> mValue;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCKVFeature);
};

class VCSeqFeature : public VCFeature {
public:
    typedef std::shared_ptr<VCSeqFeature> Ptr;
    VCSeqFeature(VCStrCRef name);
    ~VCSeqFeature() override = default;

public:
    std::string toString() const override;

public:
    volatile ObjectType mValType{OBJECT_NULL};
    std::shared_ptr<List> mValue;
    size_t getCount();

    /// Statistics are valid only if they are computable
    bool canCalculated();
    std::shared_ptr<Object> getMax();
    std::shared_ptr<Object> getMin();
    std::shared_ptr<Object> getMid();
    std::shared_ptr<Object> getAvg();
    std::shared_ptr<Object> getSum();

private:
    std::shared_ptr<Object> mSum{nullptr};
    std::shared_ptr<Object> mMin{nullptr};
    std::shared_ptr<Object> mMax{nullptr};
    std::shared_ptr<Object> mMid{nullptr};
    std::shared_ptr<Object> mAvg{nullptr};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCSeqFeature);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_FEATURE_H
