//
// Created by bytedance on 2020/8/10.
//

#include "upload_service.h"

#include "log.h"
#include "env.h"

namespace hermas {

UploadService::UploadService(const std::shared_ptr<ModuleEnv>& module_env): m_module_env(module_env) {
    m_is_start_cycle = false;
    m_cycle_handler = std::make_unique<CycleHandler>(m_module_env);
}

UploadService::~UploadService() {
    logi("hermas_upload", "~UploadService start");
    logi("hermas_upload", "~UploadService end");
}

void UploadService::StartCycle() {
    if (m_is_start_cycle.load(std::memory_order_acquire)) {
        return;
    }
    m_is_start_cycle.store(true, std::memory_order_release);
    m_cycle_handler->StartCycle();
    logi("hermas_upload", "start cycle upload, moduleid = %s", m_module_env->GetModuleId().c_str());
}

void UploadService::StopCycle() {
    if (m_is_start_cycle.load(std::memory_order_acquire)) {
        m_cycle_handler->StopCycle();
        m_is_start_cycle.store(false, std::memory_order_release);
        logi("hermas_upload", "stop cycle upload, moduleid = %s", m_module_env->GetModuleId().c_str());
    }
}

void UploadService::TriggerUpload() {
    m_cycle_handler->TriggerUpload();
}

void UploadService::UpdateFlowControlStrategy(FlowControlStrategyType type) {
    m_cycle_handler->UpdateFlowControlStrategy(type);
}

bool UploadService::IsCycleStart() {
    bool ret = m_is_start_cycle.load(std::memory_order_acquire);
    return ret;
}

} //namespace hermas
