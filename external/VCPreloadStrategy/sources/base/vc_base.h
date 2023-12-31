// Created by 黄清 on 2020/5/19.
//

#ifndef MLBase_hpp
#define MLBase_hpp
#pragma once

#include <cinttypes>
#include <cstdio>
#include <cstring>
#include <locale>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#if __has_include("vc_config.h")
#include "vc_config.h"
#endif

#define VC_NAMESPACE_BEGIN \
    namespace com {        \
    namespace bd {         \
    namespace vod {        \
    namespace ST {

#define VC_NAMESPACE_END \
    }                    \
    }                    \
    }                    \
    }

#define USING_VC_NAMESPACE using namespace com::bd::vod::ST;

///
/// struct
typedef std::map<std::string, long> LongValueMap;
typedef std::map<std::string, float> FloatValueMap;
typedef std::map<std::string, std::string> StringValueMap;

///
/// const value
#define S_OK 0
#define S_FAIL (-1)
#define S_ENABLE 1
#define S_DISABLE 0

///

#define VC_LOG_VERBOSE 0
#define VC_LOG_DEBUG 1
#define VC_LOG_INFO 2
#define VC_LOG_WARN 3
#define VC_LOG_ERROR 4
#define VC_LOG_FATAL 5

#define VC_LOG_PRINT 99
#define VC_LOG_ALOG 100

#ifdef LOG_OUTPUT
#define VC_LOG_DEFAULT VC_LOG_VERBOSE
#else
#define VC_LOG_DEFAULT VC_LOG_ERROR
#endif

#if defined(__ANDROID__)
#if defined(__GNUC__)
#ifdef __USE_MINGW_ANSI_STDIO
#if __USE_MINGW_ANSI_STDIO
#define ml_printflike(fmtarg, firstvararg) \
    __attribute__((__format__(gnu_printf, fmtarg, firstvararg)))
#else
#define ml_printflike(fmtarg, firstvararg) \
    __attribute__((__format__(printf, fmtarg, firstvararg)))
#endif
#else
#define ml_printflike(fmtarg, firstvararg) \
    __attribute__((__format__(printf, fmtarg, firstvararg)))
#endif
#endif
#elif defined(__IOS__) || defined(__MAC__)
#define ml_printflike(fmtarg, firstvararg) __printflike(fmtarg, firstvararg)
#else
#define ml_printflike(fmtarg, firstvararg)
#endif

#ifdef __cplusplus
extern "C" {
#endif

void vc_set_logger_level(int level);
bool vc_logger_enableLog(int level);
void vc_set_logger_handle(void *handle);
void vc_logger_nprintf(int level,
                       const char *tag,
                       const char *file,
                       const char *fun,
                       int line,
                       const char *format,
                       ...) ml_printflike(6, 7);
void vc_logger_method_nprintf(int level,
                              const char *tag,
                              const char *format,
                              ...) ml_printflike(3, 4);

#ifdef __cplusplus
}
#endif

#define VC_LOG_TAG "VCStrategy"

#define __FILENAME__ (std::strrchr("/" __FILE__, '/') + 1)

// void vc_logger_nprintf(int level,const char* tag,const void* p,const char*
// file,const char* fun,int line,const char* format,...);

#define LOG(LEVEL, ...)                     \
    do {                                    \
        if (vc_logger_enableLog(LEVEL)) {   \
            vc_logger_nprintf(LEVEL,        \
                              VC_LOG_TAG,   \
                              __FILENAME__, \
                              __FUNCTION__, \
                              __LINE__,     \
                              __VA_ARGS__); \
        }                                   \
    } while (0)

#ifdef LOG_OUTPUT
#define LOGV(...) LOG(VC_LOG_VERBOSE, __VA_ARGS__)
#define LOGD(...) LOG(VC_LOG_DEBUG, __VA_ARGS__)
#define LOGI(...) LOG(VC_LOG_INFO, __VA_ARGS__)
#define LOGW(...) LOG(VC_LOG_WARN, __VA_ARGS__)
#define LOGE(...) LOG(VC_LOG_ERROR, __VA_ARGS__)
#define LOGF(...) LOG(VC_LOG_FATAL, __VA_ARGS__)
#else
#define LOGV(...)
#define LOGD(...)
#define LOGI(...)
#define LOGW(...)
#define LOGE(...)
#define LOGF(...)
#endif

#define LOG_S(LEVEL, ...)                                             \
    do {                                                              \
        if (vc_logger_enableLog(LEVEL)) {                             \
            vc_logger_method_nprintf(LEVEL, VC_LOG_TAG, __VA_ARGS__); \
        }                                                             \
    } while (0)

#ifdef LOG_OUTPUT
#define LOGV_S(...) LOG_S(VC_LOG_VERBOSE, __VA_ARGS__)
#define LOGD_S(...) LOG_S(VC_LOG_DEBUG, __VA_ARGS__)
#define LOGI_S(...) LOG_S(VC_LOG_INFO, __VA_ARGS__)
#define LOGW_S(...) LOG_S(VC_LOG_WARN, __VA_ARGS__)
#define LOGE_S(...) LOG_S(VC_LOG_ERROR, __VA_ARGS__)
#define LOGF_S(...) LOG_S(VC_LOG_FATAL, __VA_ARGS__)
#else
#define LOGV_S(...)
#define LOGD_S(...)
#define LOGI_S(...)
#define LOGW_S(...)
#define LOGE_S(...)
#define LOGF_S(...)
#endif

#if defined(__TRACE__)
#define TRACE_CODE(code) code
#else
#define TRACE_CODE(code)
#endif

#define PLOG(...) LOG(VC_LOG_PRINT, __VA_ARGS__)
#define PLOG_S(...) LOG_S(VC_LOG_PRINT, __VA_ARGS__)
#define ALOG(...) LOG(VC_LOG_ALOG, __VA_ARGS__)
#define ALOG_S(...) LOG_S(VC_LOG_ALOG, __VA_ARGS__)

#define VC_DISALLOW_COPY(TypeName) TypeName(const TypeName &) = delete

#define VC_DISALLOW_ASSIGN(TypeName) \
    TypeName &operator=(const TypeName &) = delete

#define VC_DISALLOW_MOVE(TypeName)  \
    TypeName(TypeName &&) = delete; \
    TypeName &operator=(TypeName &&) = delete

#define VC_DISALLOW_COPY_AND_ASSIGN(TypeName) \
    VC_DISALLOW_COPY(TypeName);               \
    VC_DISALLOW_ASSIGN(TypeName)

#define VC_DISALLOW_COPY_ASSIGN_AND_MOVE(TypeName) \
    VC_DISALLOW_COPY_AND_ASSIGN(TypeName);         \
    VC_DISALLOW_MOVE(TypeName)

#define VC_DISALLOW_IMPLICIT_CONSTRUCTORS(TypeName) \
    TypeName() = delete;                            \
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(TypeName)

#define VC_HANDLE_EINTR(x)                                       \
    ({                                                           \
        int eintr_wrapper_counter = 0;                           \
        decltype(x) eintr_wrapper_result;                        \
        do {                                                     \
            eintr_wrapper_result = (x);                          \
        } while (eintr_wrapper_result == -1 && errno == EINTR && \
                 eintr_wrapper_counter++ < 100);                 \
        eintr_wrapper_result;                                    \
    })

//
#define MEMCPY_STRING(dst, src)      \
    if (src != nullptr) {            \
        size_t len = strlen(src);    \
        if (dst != nullptr) {        \
            delete dst;              \
            dst = nullptr;           \
        }                            \
        if (len > 0) {               \
            dst = new char[len + 1]; \
            memcpy(dst, src, len);   \
            dst[len] = 0;            \
        }                            \
    }

VC_NAMESPACE_BEGIN

/// MARK: Base Type

typedef std::string VCString;
typedef std::string &VCStrRef;
typedef const std::string &VCStrCRef;
#define ToString(x) std::to_string(x)

/// MARK: Base Interface

class IVCPrintable {
public:
    virtual ~IVCPrintable() = default;
    virtual std::string toString(void) const = 0;
};

/// MARK: - base template
///
template <typename T>
struct VCGreaterTemplate {
    bool operator()(std::shared_ptr<T> const &l,
                    std::shared_ptr<T> const &r) const {
        return *l > *r;
    }
};

template <typename T>
struct VCLessTemplate {
    bool operator()(std::shared_ptr<T> const &l,
                    std::shared_ptr<T> const &r) const {
        return *l < *r;
    }
};

template <typename... Args>
inline std::string string_format(const char *format, Args &&...args) {
    char unused[2];
    int size = std::snprintf(unused, 0, format, args...);
    if (size < 0) {
        LOGE("[vcbase] Error during formatting: %s", format);
        return {};
    }
    std::vector<char> buf(size + 1); // +1 for '\0' terminator
    std::snprintf(buf.data(), buf.size(), format, args...);
    return std::string(buf.data(), size);
}

template <typename CharT>
inline std::basic_string<CharT> tolower(std::basic_string<CharT> s) {
    auto &f = std::use_facet<std::ctype<CharT>>(std::locale());
    f.tolower(&s[0], &s[0] + s.size());
    return s;
}

VC_NAMESPACE_END

#ifndef __cpp_lib_as_const
// This should appear in <utility> since C++17
namespace std {
template <class T>
constexpr typename std::add_const<T>::type &as_const(T &t) noexcept {
    return t;
}
template <class T>
void as_const(T &&t) = delete;
} // namespace std
#endif

#endif /* MLBase_hpp */
