//
// Created by bytedance on 2021/4/16.
//
#ifndef DAVINCIRESOURCE_RESOURCECHECKER_H
#define DAVINCIRESOURCE_RESOURCECHECKER_H
#include <string>
namespace davinci {
    class ResponseChecker {
    public:
        virtual std::string &getMessage() = 0;

        virtual int getStatusCode() = 0;
    };
}
#endif//DAVINCIRESOURCE_RESOURCECHECKER_H
