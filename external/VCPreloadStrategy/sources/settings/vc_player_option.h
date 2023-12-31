//
// Created by 黄清 on 2022/5/31.
//

#ifndef PRELOAD_VC_PLAYER_OPTION_H
#define PRELOAD_VC_PLAYER_OPTION_H
#include "vc_base.h"
#include "vc_json.h"
#include "vc_shared_mutex.h"

VC_NAMESPACE_BEGIN

class VCPlayerItem;

class VCPlayerOption : public IVCPrintable {
    typedef enum : int {
        TypeUn = -1,
        TypeInt = 0,
        TypeFloat = 1,
        TypeInt64 = 2,
        TypeString = 3,
    } Type;

public:
    explicit VCPlayerOption(const VCJson &json);
    ~VCPlayerOption() noexcept override = default;

public:
    void configPlayer(VCPlayerItem &playerItem);
    int getKey() const;
    int getIntValue() const;
    float getFloatValue() const;
    VCString getStringValue() const;
    int64_t getInt64Value() const;
    bool isValid();

public:
    std::string toString() const override;

private:
    int mKey{-1};
    Type mType{TypeUn};

    union {
        int i32;
        int64_t i64;
        float f32;
    } mValue{};

    VCString mStringValue;

    std::shared_ptr<std::vector<VCString>> mAllowTagList{nullptr};
    std::shared_ptr<std::vector<VCString>> mBlockTagList{nullptr};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayerOption);
};

class VCPlayerOptionHelper : public IVCPrintable {
public:
    VCPlayerOptionHelper() = default;
    ~VCPlayerOptionHelper() override = default;

public:
    void updateJson(const VCJson &json);
    void preparePlayer(VCPlayerItem &playerItem);
    std::string toString() const override;

private:
    void _updateJson(const VCJson &json);

private:
    int mEnable{false};
    shared_mutex mOptionMutex;
    std::vector<std::shared_ptr<VCPlayerOption>> mPlayerOptions;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayerOptionHelper);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAYER_OPTION_H
