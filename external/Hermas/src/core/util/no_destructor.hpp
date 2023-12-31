//
//  no_destructor.hpp
//  Hermas
//
//  Created by 崔晓兵 on 7/7/2022.
//

#ifndef no_destructor_hpp
#define no_destructor_hpp


#include <type_traits>

namespace hermas {

template <typename T>
class NoDestructor {
public:
    // Not constexpr; just write static constexpr T x = ...; if the value should
    // be a constexpr.
    template <typename... Args>
    explicit NoDestructor(Args&&... args) {
        static_assert(sizeof(storage_) >= sizeof(T), "storage_ is not large enough to hold the instance");
        new (&storage_) T(std::forward<Args>(args)...);
    }
    
    // Allows copy and move construction of the contained type, to allow
    // construction from an initializer list, e.g. for std::vector.
    explicit NoDestructor(const T& x) { new (storage_) T(x); }
    
    explicit NoDestructor(T&& x) { new (storage_) T(std::move(x)); }
    
    NoDestructor(const NoDestructor&) = delete;
    
    NoDestructor& operator=(const NoDestructor&) = delete;
    
    ~NoDestructor() = default;
    
    const T& operator*() const { return *get(); }
    
    T& operator*() { return *get(); }
    
    const T* operator->() const { return get(); }
    
    T* operator->() { return get(); }
    
    const T* get() const { return reinterpret_cast<const T*>(storage_); }
    
    T* get() { return reinterpret_cast<T*>(storage_); }
    
private:
    alignas(T) char storage_[sizeof(T)];
};

}
#endif /* no_destructor_hpp */
