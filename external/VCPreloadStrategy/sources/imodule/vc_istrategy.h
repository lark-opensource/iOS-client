//
// Created by 黄清 on 2021/9/29.
//

#ifndef PRELOAD_VC_ISTRATEGY_H
#define PRELOAD_VC_ISTRATEGY_H
#pragma once

#include "vc_base.h"
#include "vc_context.h"
#include "vc_strategy_result.h"

VC_NAMESPACE_BEGIN

class IVCStrategy : public IVCPrintable {
public:
    typedef std::shared_ptr<IVCStrategy> Ptr;

public:
    IVCStrategy(VCModuleType type, const std::string &name);
    virtual ~IVCStrategy() override;

public: /// Setter
    void setContext(IVCContext *context);

public: /// probe
    virtual std::shared_ptr<VCStrategyResult>
    probeAction(const std::shared_ptr<VCMessage> &msg) = 0;

public:
    std::string toString() const override;

public:
    virtual VCModuleType getType();
    virtual std::string getName();
    virtual std::string getVersionString();

protected:
    VCModuleType mType{VCModuleTypeUnknown};
    std::string mName;
    std::string mVersionString;
    IVCContext *mContext{nullptr};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(IVCStrategy);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_ISTRATEGY_H
