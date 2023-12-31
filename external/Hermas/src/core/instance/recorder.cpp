#include "recorder.h"
#include "hermas_internal.h"
#include "log.h"

namespace hermas {

Recorder::Recorder(const std::shared_ptr<HermasInternal>& hermas_internal, enum RECORD_INTERVAL interval)
    : m_hermas_internal(hermas_internal), m_interval(interval) {}

void Recorder::DoRecord(const std::string& data) {
    if (m_hermas_internal != nullptr) {
        m_hermas_internal->Record(m_interval, data);
    }
}

void Recorder::DoRecordCache(const std::string& data) {
    if (m_hermas_internal != nullptr) {
        m_hermas_internal->RecordCache(data);
    }
}

void Recorder::DoRecordLocal(const std::string& data, bool force_save) {
    auto& block = GlobalEnv::GetInstance().GetStopWriteToDiskWhenUnhitBlock();
    if (block && block() && !force_save) {
        return;
    }
    
    if (m_hermas_internal != nullptr) {
        m_hermas_internal->RecordLocal(data);
    }
}

} // namespace hermas
