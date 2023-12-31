#pragma once

#include <string>
#include "constants.h"
#include "recorder.h"

namespace hermas { class HermasInternal; }

namespace hermas {

class Recorder final {
public:
    Recorder(const std::shared_ptr<HermasInternal>& hermas_internal, enum RECORD_INTERVAL interval);
    ~Recorder() = default;

    void DoRecord(const std::string& json);
    void DoRecordCache(const std::string& json);
    void DoRecordLocal(const std::string& json, bool force_save);

private:
    std::shared_ptr<HermasInternal> m_hermas_internal;
    RECORD_INTERVAL m_interval;
};

} //namespace hermas

