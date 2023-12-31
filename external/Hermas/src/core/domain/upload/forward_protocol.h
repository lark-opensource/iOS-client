//
//  forward_protocol.h
//  Hermas
//
//  Created by 崔晓兵 on 23/2/2022.
//

#ifndef forward_protocol_h
#define forward_protocol_h

#include <memory>
#include <string>
#include <vector>

namespace hermas {

struct RecordData {
    std::string header;
    std::vector<std::string> body;
};

struct IForwardService {
    virtual ~IForwardService() = default;
    
    virtual void forward(const std::vector<std::unique_ptr<RecordData>>& record_data) = 0;
};

}

#endif /* forward_protocol_h */
