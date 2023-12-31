//
//  aggregate_service.hpp
//  Hermas
//
//  Created by 崔晓兵 on 10/2/2022.
//

#ifndef aggregate_service_hpp
#define aggregate_service_hpp

#include <string>
#include <functional>

#include "env.h"
#include "log.h"
#include "base_domain.h"
#include "record_aggregation.h"


namespace hermas {

class RecordService;

class AggregateServiceClient {
public:
    virtual ~AggregateServiceClient() = default;
    virtual void OnAggregateFinish(const std::string& data) = 0;
};


class AggregateService {
 
public:
    explicit AggregateService(const std::shared_ptr<Env>& env);
    
    virtual ~AggregateService(){}
    
    void Aggregate(const std::string& data);
    
    void StopAggregate(bool isLaunchStop=false);
    
    void SetupClient(const std::weak_ptr<AggregateServiceClient>& client);
    
    void Close();
    
    void FreeFiles();
    
private:
    std::shared_ptr<Env> m_env;
    std::unique_ptr<RecordAggregation> m_aggregator;
    std::weak_ptr<AggregateServiceClient> m_client;
    
    int64_t m_last_stop_aggre_timestamp;
};

}

#endif /* aggregate_service_hpp */
