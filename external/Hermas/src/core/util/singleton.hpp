//
//  singleton.hpp
//  Hermas
//
//  Created by 崔晓兵 on 29/5/2022.
//

#ifndef singleton_hpp
#define singleton_hpp

#include <memory>
#include <mutex>
#include "no_destructor.hpp"

namespace hermas {

template <typename Derived>
class Singleton {
public:
    template<typename ...Args>
    static std::unique_ptr<Derived>& GetInstance(const Args& ...args) {
        static NoDestructor<std::unique_ptr<Derived>> m_instance;
        static std::once_flag m_flag;
        std::call_once(m_flag, [](auto ...args) {
            (*m_instance).reset(new Derived(std::forward<Args>(args)...));
        }, args...);
        return *m_instance;
    }
protected:
    Singleton() = default;
    ~Singleton() = default;
private:
    Singleton(Singleton&) = delete;
};

} /* namesapce hermas */

#endif /* singleton_hpp */
