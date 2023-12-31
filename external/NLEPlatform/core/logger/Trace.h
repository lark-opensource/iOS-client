//
// Created by keyou on 8/6/21.
//

#ifndef NLEANDROID_TRACE_H
#define NLEANDROID_TRACE_H

#include "nle_export.h"
#include <string>

// DCHECK means debug check, means to only be used in debug mode,
// as we want the app crash as early as possible at the debug mode.
// TODO(zhangkui): Refactor DCHECK use __builtin_expect for performance
#define DCHECK(x) assert(x)

namespace nle {
    class NLE_EXPORT_CLASS ScopedTrace final{
    public:
        ScopedTrace(const char *name);

        ScopedTrace(const std::string &name);

        ~ScopedTrace();
    };

#define GET_STR(x) #x
#define ___STR1(str1, str2) str1##str2
#define ___STR(str1, str2) ___STR1(str1,str2)
#define VAR_NAME(name) ___STR(name,__LINE__)
#define ___STR2(x) GET_STR(x)
#define VAR_STR(value) ___STR2(VAR_NAME(value))
#define ATRACE_NAME(name) nle::ScopedTrace VAR_NAME(___tracer_)(name)
#define ___ATRACE_CALL0() ATRACE_NAME(__FUNCTION__)
#define ___ATRACE_CALL1(x) ATRACE_NAME(std::string(__FUNCTION__) + ": " + (x))
#define ___MACRO_NAME(_0,_1,NAME,...) NAME
#define ATRACE_CALL(...) ___MACRO_NAME(_0, ##__VA_ARGS__, ___ATRACE_CALL1, ___ATRACE_CALL0)(__VA_ARGS__)
}

#endif //NLEANDROID_TRACE_H
