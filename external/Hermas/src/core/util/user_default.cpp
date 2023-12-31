//
//  user_default.cpp
//  Hermas
//
//  Created by 崔晓兵 on 21/2/2022.
//

#include "user_default.h"
#include "rwlock.h"
#include <stdio.h>

namespace hermas {

std::unique_ptr<UserDefaultProtocol> * UserDefault::impl = nullptr;

void UserDefault::RegisterInstance(std::unique_ptr<UserDefaultProtocol> instance) {
    static std::unique_ptr<UserDefaultProtocol> impl_internal = std::move(instance);
    impl = &impl_internal;
}

std::string UserDefault::Read(const std::string& key) {
    return (*impl)->Read(key);
}

void UserDefault::Write(const std::string& key, const std::string& value) {
    return (*impl)->Write(key, value);
}

void UserDefault::Remove(const std::string &key) {
    (*impl)->Remove(key);
}

}


