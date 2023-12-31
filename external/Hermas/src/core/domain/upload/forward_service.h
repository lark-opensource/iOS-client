//
//  forward_service.h
//  Hermas
//
//  Created by 崔晓兵 on 23/2/2022.
//

#ifndef forward_service_hpp
#define forward_service_hpp

#include "forward_protocol.h"
#include "env.h"

namespace hermas {

class ForwardService : public IForwardService {

public:
    ForwardService(const std::shared_ptr<ModuleEnv>& module_env) : m_module_env(module_env) {}
    ~ForwardService() = default;

    virtual void forward(const std::vector<std::unique_ptr<RecordData>>& record_data) override;
    
private:
    std::shared_ptr<ModuleEnv> m_module_env;
};

}

#endif /* forward_service_hpp */
