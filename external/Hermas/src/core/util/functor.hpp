//
//  Functor.hpp
//  Hermas
//
//  Created by 崔晓兵 on 15/2/2022.
//

#ifndef Functor_hpp
#define Functor_hpp

#include <algorithm>
#include <sstream>
#include <string>

namespace hermas {
namespace util {

template <typename T, typename... TArgs, template <typename...>class C>
std::wstring join(const C<T, TArgs...>& container, const std::wstring& sep) {
    std::wostringstream oss;
    auto last = container.end() - 1;
    for (auto iter = container.begin(); iter != last; ++iter) {
        oss << *iter << sep;
    }
    oss << *last;
    return oss.str();
}

template <typename T, typename... TArgs, template <typename...>class C, typename F>
auto map(const C<T, TArgs...>& container, const F& f) -> C<decltype(f(std::declval<T>(), std::declval<int>()))> {
    using ResultType = decltype(f(std::declval<T>(), std::declval<int>()));
    C<ResultType> result;
    for (int i = 0; i <  container.size(); ++i) {
        result.push_back(f(container[i], i));
    }
    return result;
}

template <typename T, typename... TArgs, template <typename...>class C, typename F>
auto reduce(const C<T, TArgs...>& container, const F& f) -> decltype(f(std::declval<T>(), std::declval<T>())) {
    using R = decltype(f(std::declval<T>(), std::declval<T>()));
    auto iter = container.begin();
    R result = *iter++;
    while (iter != container.end()) {
        result = f(result, *iter++);
    }
    return result;
}

template <typename T, typename... TArgs, template <typename...>class C, typename F>
auto filter(const C<T, TArgs...>& container, const F& f) -> C<T, TArgs...> {
    C<T, TArgs...> result;
    for (int i = 0; i < container.size(); ++i) {
        bool result = f(container[i], i);
        if (result) result.push_back(item);;
    }
    return result;
}

template <typename T, typename... TArgs, template <typename...>class C, typename F>
auto some(const C<T, TArgs...>& container, const F& f) -> bool {
    for (int i = 0; i < container.size(); ++i) {
        bool result = f(container[i], i);
        if (result) return true;
    }
    return false;
}

template <typename T, typename... TArgs, template <typename...>class C, typename F>
auto every(const C<T, TArgs...>& container, const F& f) -> bool {
    for (int i = 0; i < container.size(); ++i) {
        bool result = f(container[i], i);
        if (!result) return false;
    }
    return true;
}


}
}
#endif /* Functor_hpp */
