/**
 * Redirect printf to your os log
 *
 * For Non-Audio SDK Developer:
 * Generally, you should include this header, and call redirect_printf_to_oslog or redirect_print_string_to_oslog
 * before calling any audio modules.
 *
 * Your logging system needs to implement at least one of the logger function that meets the format above.
 * (Sample code is available in print2log.c)
 *
 * ** Note: This header will re-define printf to use for redirecting,
 *  if you need to maintain the behavior of the original printf, you need to
 *  #define PROTECT_MY_PRINTF
 *  before
 *  #include "print2log.h"
 *
 * For AudioSDK Developer:
 * Generally, including this header will automatically redirect all printf to the logger outside.
 * However, if your c/cpp/h file needs the original printf function, you should
 * #define PROTECT_MY_PRINTF
 * before
 * #include "print2log.h"
 *
 * You can use printfE for logging errors, and printfD for logging debug info like Log.E or log.D does.
 *
 * TODO: Support PRINTF2LOG_TAG in the next submit
 */

#ifndef PRINT_TO_OSLOG
#define PRINT_TO_OSLOG

#include <stdarg.h>
#include <stdint.h>
#include "ae_defs.h"
#include <string.h>

#ifndef PRIx64
#define PRIx64 "llx"
#endif

#ifndef PRIX64
#define PRIX64 "llX"
#endif

#ifndef PRId64
#define PRId64 "lld"
#endif

#ifndef ANDROID
#define PRO_ENDL "\n"
#else
#define PRO_ENDL ""
#endif

#ifdef printf
#undef printf
#endif

#ifdef ANDROID
// Keep this until Android VESDK enables logging INFO
#define TREAT_INFO_AS_WARNING
#endif

typedef enum GENERIC_LOG_LEVEL {
    GLL_UNKNOWN = 0,
    GLL_DEFAULT, /* only for SetMinPriority() */
    GLL_VERBOSE,
    GLL_DEBUG,
    GLL_INFO,
    GLL_WARN,
    GLL_ERROR,
    GLL_FATAL,
    GLL_SILENT, /* only for SetMinPriority(); must be last */
} GENERIC_LOG_LEVEL;

#ifdef __cplusplus
extern "C" {
#endif

MAMMON_EXPORT int printfL(int logLevel, const char* format, ...);

void redirect_print_string_to_oslog(int (*osLogger)(int logLevel, const char* msg));
void unregister_redirect_print_string_to_oslog(int (*osLogger)(int logLevel, const char* msg));

void redirect_printf_to_oslog(int (*osLogger)(int logLevel, const char* format, ...));
void unregister_redirect_printf_to_oslog(int (*osLogger)(int logLevel, const char* format, ...));

void redirect_print_string_to_oslog_with_data(int (*osLogger)(void* data, int logLevel, const char* msg), void* data);
void unregister_redirect_print_string_to_oslog_with_data(int (*osLogger)(void* data, int logLevel, const char* msg));

void redirect_printf_to_oslog_with_data(int (*osLogger)(void* data, int logLevel, const char* format, ...), void* data);
void unregister_redirect_printf_to_oslog_with_data(int (*osLogger)(void* data, int logLevel, const char* format, ...));

void set_print_log_output_level(GENERIC_LOG_LEVEL level);

void print_file_content(const char* file, int maxLen, int includeTextMode);
void print_raw_content(const void* raw, int rawSize, int maxDispLen, int includeTextMode);

#ifdef __cplusplus
}
#endif

#if defined(WIN32) || defined(_WIN32) || defined(_WIN32_) || defined(WIN64) || defined(_WIN64) || defined(_WIN64_)
// windows系统下：
#define FILENAME(x) strrchr(x,'\\')?strrchr(x,'\\')+1:x
#else
// linux系统下：
#define FILENAME(x) strrchr(x,'/')?strrchr(x,'/')+1:x
#endif

#ifndef PROTECT_MY_PRINTF
#define printf(format, ...) printfL(GLL_INFO, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)
#endif

#ifdef PRODUCT_BUILD

// Speed up in Product-Build

#define printfV(format, ...)
#define printfD(format, ...)

#else

#define printfV(format, ...) printfL(GLL_VERBOSE, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)
#define printfD(format, ...) printfL(GLL_DEBUG, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)

#endif

#ifdef TREAT_INFO_AS_WARNING
#define printfI(format, ...) printfL(GLL_WARN, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)
#else
#define printfI(format, ...) printfL(GLL_INFO, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)
#endif

#define printfW(format, ...) printfL(GLL_WARN, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)
#define printfE(format, ...) printfL(GLL_ERROR, "[SAMICORE: %s@%s,%d] " format "\n", __func__, FILENAME(__FILE__), __LINE__, ##__VA_ARGS__)

#endif
