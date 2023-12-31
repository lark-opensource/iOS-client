//
//  service_factory.hpp
//  Hermas
//
//  Created by 崔晓兵 on 30/5/2022.
//

#ifndef factory_hpp
#define factory_hpp

#include "weak_handler.h"
#include "rwlock.h"
#include "no_destructor.hpp"
#include <map>

namespace hermas {

template <typename T, typename ...Args>
typename std::enable_if<std::is_same<typename std::decay<T>::type, std::shared_ptr<ModuleEnv>>::value, std::string>::type
DecayFirstParam(T&& t, Args&& ...arg) {
    return t->GetModuleId();
}

template <typename T, typename ...Args>
typename std::enable_if<std::is_same<typename std::decay<T>::type, std::shared_ptr<Env>>::value, std::string>::type
DecayFirstParam(T&& t, Args&& ...arg) {
    return t->GetIdentify();
}

template <typename T, typename ...Args>
typename std::enable_if<std::is_same<typename std::decay<T>::type, std::string>::value, std::string>::type
DecayFirstParam(T&& t, Args&& ...arg) {
    std::string copy = t;
    return copy;
}

template <typename Derived, bool ThreadSafe = true>
class ServiceFactory {
public:
    using WeakMap = WeakWrapper<std::map<std::string, std::unique_ptr<Derived>>>;
    
    static StaticWrapper<WeakMap>& GetMap() {
        static NoDestructor<StaticWrapper<WeakMap>> container_wrap;
        return *container_wrap;
    }
    
    static rwlock& GetLock() {
        static NoDestructor<rwlock> lock_wrap;
        return *lock_wrap;
    }
    
    template <typename ...Args>
    static std::unique_ptr<Derived>& GetInstance(Args&& ...args) {
        auto& container = GetMap();
        auto& lock = GetLock();
        
        auto key = DecayFirstParam(std::forward<Args>(args)...);
        
        if (ThreadSafe) lock.lock_shared();
        auto safe_container = container.SafeGet();
        auto map_ptr = safe_container.Lock();
        auto& map = map_ptr->GetItem();
        auto iter = map.find(key);
        if (iter != map.end() && map[key]) {
            std::unique_ptr<Derived>& res = map[key];
            if (ThreadSafe) lock.unlock_shared();
            return res;
        }
        if (ThreadSafe) lock.unlock_shared();

        if (ThreadSafe) lock.lock();
        
        if (map.find(key) == map.end() || map[key] == nullptr) {
            map[key] = std::unique_ptr<Derived>(new Derived(std::forward<Args>(args)...));
        }
        std::unique_ptr<Derived>& res = map[key];
        if (ThreadSafe) lock.unlock();
        return res;
    }
    
    template <typename ...Args>
    static void DestroyInstance(Args&& ...args) {
        auto& container = GetMap();
        auto& lock = GetLock();
        auto key = DecayFirstParam(std::forward<Args>(args)...);
        
        if (ThreadSafe) lock.lock();
        auto map_ptr = container.SafeGet().Lock();
        auto& map = map_ptr->GetItem();
        
        auto iter = map.find(key);
        if (iter != map.end()) {
            map.erase(iter);
        }
        if (ThreadSafe) lock.unlock();
    }
    
protected:
    ServiceFactory() = default;
    ~ServiceFactory() = default;
private:
    ServiceFactory(ServiceFactory&) = delete;
};

} /* namesapce hermas */



#endif /* factory_hpp */
