//
// Created by zhangyeqi on 2019-12-13.
//

#ifndef CUTSAMEAPP_TEMPLATEEXCEPTION_H
#define CUTSAMEAPP_TEMPLATEEXCEPTION_H

#include <string>

using std::string;

namespace cut {
    class TemplateException : public std::runtime_error {
    public:
        explicit TemplateException(const string &message) noexcept : runtime_error(message) {}
    };
}
#endif //CUTSAMEAPP_TEMPLATEEXCEPTION_H
