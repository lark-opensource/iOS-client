//
//  aggregate_service.cpp
//  Hermas
//
//  Created by 崔晓兵 on 10/2/2022.
//

#include "aggregate_service.h"
#include "record_service.h"
#include "record_aggregation.h"
#include "time_util.h"

#define STOPAGGREGATEINTERVAL (2 * 60 * 1000)

namespace hermas {

AggregateService::AggregateService(const std::shared_ptr<Env>& env)
    : m_env(env)
    , m_last_stop_aggre_timestamp(0) {
    // create aggregator
    m_aggregator = std::make_unique<RecordAggregation>(m_env->GetAid(), m_env->GetModuleId(), GlobalEnv::GetInstance().GetRootPathName(), m_env->GetModuleEnv()->GetAggreFileSize(), m_env->GetModuleEnv()->GetAggreFileConfig(), m_env->GetModuleEnv()->GetAggreIntoMax());
    // setup ready callback
    m_aggregator->callback = [this](const std::string& data) -> void {
        std::shared_ptr<AggregateServiceClient> client = m_client.lock();
        if (client) client->OnAggregateFinish(data);
    };
}

void AggregateService::Aggregate(const std::string& data) {
    m_aggregator->DoRecordAggregation(const_cast<std::string&>(data));
}

void AggregateService::StopAggregate(bool isLaunchStop) {
    if ((CurTimeMillis() - m_last_stop_aggre_timestamp) > STOPAGGREGATEINTERVAL) {
        m_last_stop_aggre_timestamp = CurTimeMillis();
        if (isLaunchStop) {
            m_aggregator->LaunchReportForAggre();
        } else {
            m_aggregator->ResetAggre();
        }
    }
}

void AggregateService::SetupClient(const std::weak_ptr<AggregateServiceClient>& client) {
    m_client = client;
}

void AggregateService::Close() {
    m_aggregator->Close();
}

void AggregateService::FreeFiles() {
    m_aggregator->FreeFiles();
}

}
