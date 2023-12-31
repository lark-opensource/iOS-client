//
//  UserDefault_iOS.h
//  Hermas
//
//  Created by 崔晓兵 on 28/4/2022.
//

#ifndef UserDefault_iOS_hpp
#define UserDefault_iOS_hpp

#include "user_default.h"

namespace hermas {

class UserDefault_iOS : public UserDefaultProtocol {
public:
    virtual std::string Read(const std::string& key) override;
    virtual void Write(const std::string& key, const std::string& value) override;
    virtual void Remove(const std::string& key) override;
};

}

#endif /* UserDefault_iOS_hpp */
