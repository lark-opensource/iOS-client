//
// Created by xuzhi on 2021/7/12.
//

#ifndef HERMAS_BASE_DOMAIN_H
#define HERMAS_BASE_DOMAIN_H

#include <memory>
#include <vector>
#ifndef HERMAS_WIN
#include <unistd.h>
#endif

#include "log.h"
#include "any.h"

namespace hermas {
namespace infrastruct {
    template <class... Depend>
    class BaseDomainService {
    public:
        virtual ~BaseDomainService() = default;

        virtual void InjectDepend(Depend... args) {}
    };
} //namespace infrastruct
} //namespace hermas

#endif //HERMAS_BASE_DOMAIN_H
