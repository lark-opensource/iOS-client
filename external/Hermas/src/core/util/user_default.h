//
//  user_default.hpp
//  Hermas
//
//  Created by 崔晓兵 on 21/2/2022.
//

#ifndef user_default_hpp
#define user_default_hpp

#include <memory>
#include <string>


namespace hermas {

class UserDefaultProtocol {
public:
    virtual ~UserDefaultProtocol() = default;
    virtual std::string Read(const std::string& key) = 0;
    virtual void Write(const std::string& key, const std::string& value) = 0;
    virtual void Remove(const std::string& key) = 0;
};

class UserDefault {
public:
    static void RegisterInstance(std::unique_ptr<UserDefaultProtocol> instance);
    
    static std::string Read(const std::string& key);
    static void Write(const std::string& key, const std::string& value);
    static void Remove(const std::string& key);
private:
    static std::unique_ptr<UserDefaultProtocol> *impl;
};

}

#endif /* user_default_hpp */
