//
// Created by bytedance on 2020/8/10.
//

#ifndef HERMAS_UPLOAD_SERVICE_H
#define HERMAS_UPLOAD_SERVICE_H

#include <string>
#include <atomic>
#include <set>

#include "cycle_handler.h"
#include "base_domain.h"
#include "flow_control.h"
#include "service_factory.hpp"


namespace hermas {
class IFlowControlStrategy;

class UploadService final : public ServiceFactory<UploadService> {
public:
    ~UploadService();
    
private:
    explicit UploadService(const std::shared_ptr<ModuleEnv>& module_env);
    friend class ServiceFactory<UploadService>;

public:
    void StartCycle();
    void StopCycle();
    void TriggerUpload();
    void UpdateFlowControlStrategy(FlowControlStrategyType type);
    bool IsCycleStart();
private:
    std::shared_ptr<ModuleEnv> m_module_env;
    std::atomic<bool> m_is_start_cycle;
    std::unique_ptr<CycleHandler> m_cycle_handler;
};

} //namespace hermas


#endif //HERMAS_UPLOAD_SERVICE_H
