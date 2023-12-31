//
//  hmd_logger.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

// ============================================================================
#pragma mark - (internal) -
// ============================================================================

#ifndef HDR_HMDLogger_h
#define HDR_HMDLogger_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>

void i_hmdlog_logC(const char* level, const char* file, int line, const char* function, const char* fmt, ...);

void i_hmdlog_logCBasic(const char* fmt, ...);

#define i_HMDLOG_FULL i_hmdlog_logC
#define i_HMDLOG_BASIC i_hmdlog_logCBasic

//#endif  // __OBJC__

/* Back up any existing defines by the same name */
#ifdef HMD_NONE
#define HMDLOG_BAK_NONE HMD_NONE
#undef HMD_NONE
#endif
#ifdef ERROR
#define HMDLOG_BAK_ERROR ERROR
#undef ERROR
#endif
#ifdef WARN
#define HMDLOG_BAK_WARN WARN
#undef WARN
#endif
#ifdef INFO
#define HMDLOG_BAK_INFO INFO
#undef INFO
#endif
#ifdef DEBUG
#define HMDLOG_BAK_DEBUG DEBUG
#undef DEBUG
#endif
#ifdef TRACE
#define HMDLOG_BAK_TRACE TRACE
#undef TRACE
#endif

#define HMDLogger_Level_None 0
#define HMDLogger_Level_Error 10
#define HMDLogger_Level_Warn 20
#define HMDLogger_Level_Info 30
#define HMDLogger_Level_Debug 40
#define HMDLogger_Level_Trace 50

#define HMD_NONE HMDLogger_Level_None
#define ERROR HMDLogger_Level_Error
#define WARN HMDLogger_Level_Warn
#define INFO HMDLogger_Level_Info
#define DEBUG HMDLogger_Level_Debug
#define TRACE HMDLogger_Level_Trace

#define ERROR_TAG   "ERROR"
#define WARN_TAG    "WARN "
#define INFO_TAG    "INFO "
#define DEBUG_TAG   "DEBUG"
#define TRACE_TAG   "TRACE"

#ifndef HMDLogger_Level
#define HMDLogger_Level HMD_NONE
#endif


#include "HMDCrashSDKLog.h"
#define a_HMDLOG_FULL(LEVEL, FMT, ...) SDKLogStr(LEVEL, __HMD_FILE_NAME__, __LINE__, FMT, ##__VA_ARGS__);



// ============================================================================
#pragma mark - API -
// ============================================================================

/** Tests if the logger would print at the specified level.
 *
 * @param LEVEL The level to test for. One of:
 *            HMDLogger_Level_Error,
 *            HMDLogger_Level_Warn,
 *            HMDLogger_Level_Info,
 *            HMDLogger_Level_Debug,
 *            HMDLogger_Level_Trace,
 *
 * @return TRUE if the logger would print at the specified level.
 */
#define HMDLOG_PRINTS_AT_LEVEL(LEVEL) (HMDLogger_Level >= LEVEL)

/** Log a message regardless of the log settings.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#define HMDLOG_ALWAYS(FMT, ...) a_HMDLOG_FULL("FORCE", FMT, ##__VA_ARGS__)
#define HMDLOG_BASIC_ALWAYS(FMT, ...) i_HMDLOG_BASIC(FMT, ##__VA_ARGS__)

/** Log an error.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if HMDLOG_PRINTS_AT_LEVEL(HMDLogger_Level_Error)
#define HMDLOG_ERROR(FMT, ...) a_HMDLOG_FULL(ERROR_TAG, FMT, ##__VA_ARGS__)
#define HMDLOG_BASIC_ERROR(FMT, ...) i_HMDLOG_BASIC(FMT, ##__VA_ARGS__)
#else
#define HMDLOG_ERROR(FMT, ...)
#define HMDLOG_BASIC_ERROR(FMT, ...)
#endif

/** Log a warning.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if HMDLOG_PRINTS_AT_LEVEL(HMDLogger_Level_Warn)
#define HMDLOG_WARN(FMT, ...) a_HMDLOG_FULL(WARN_TAG, FMT, ##__VA_ARGS__)
#define HMDLOG_BASIC_WARN(FMT, ...) i_HMDLOG_BASIC(FMT, ##__VA_ARGS__)
#else
#define HMDLOG_WARN(FMT, ...)
#define HMDLOG_BASIC_WARN(FMT, ...)
#endif

/** Log an info message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if HMDLOG_PRINTS_AT_LEVEL(HMDLogger_Level_Info)
#define HMDLOG_INFO(FMT, ...) a_HMDLOG_FULL(INFO_TAG, FMT, ##__VA_ARGS__)
#define HMDLOG_BASIC_INFO(FMT, ...) i_HMDLOG_BASIC(FMT, ##__VA_ARGS__)
#else
#define HMDLOG_INFO(FMT, ...)
#define HMDLOG_BASIC_INFO(FMT, ...)
#endif

/** Log a debug message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if HMDLOG_PRINTS_AT_LEVEL(HMDLogger_Level_Debug)
#define HMDLOG_DEBUG(FMT, ...) a_HMDLOG_FULL(DEBUG_TAG, FMT, ##__VA_ARGS__)
#define HMDLOG_BASIC_DEBUG(FMT, ...) i_HMDLOG_BASIC(FMT, ##__VA_ARGS__)
#else
#define HMDLOG_DEBUG(FMT, ...)
#define HMDLOG_BASIC_DEBUG(FMT, ...)
#endif

/** Log a trace message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if HMDLOG_PRINTS_AT_LEVEL(HMDLogger_Level_Trace)
#define HMDLOG_TRACE(FMT, ...) a_HMDLOG_FULL(TRACE_TAG, FMT, ##__VA_ARGS__)
#define HMDLOG_BASIC_TRACE(FMT, ...) i_HMDLOG_BASIC(FMT, ##__VA_ARGS__)
#else
#define HMDLOG_TRACE(FMT, ...)
#define HMDLOG_BASIC_TRACE(FMT, ...)
#endif

// ============================================================================
#pragma mark - (internal) -
// ============================================================================

/* Put everything back to the way we found it. */
#undef ERROR
#ifdef HMDLOG_BAK_ERROR
#define ERROR HMDLOG_BAK_ERROR
#undef HMDLOG_BAK_ERROR
#endif
#undef WARNING
#ifdef HMDLOG_BAK_WARN
#define WARNING HMDLOG_BAK_WARN
#undef HMDLOG_BAK_WARN
#endif
#undef INFO
#ifdef HMDLOG_BAK_INFO
#define INFO HMDLOG_BAK_INFO
#undef HMDLOG_BAK_INFO
#endif
#undef DEBUG
#ifdef HMDLOG_BAK_DEBUG
#define DEBUG HMDLOG_BAK_DEBUG
#undef HMDLOG_BAK_DEBUG
#endif
#undef TRACE
#ifdef HMDLOG_BAK_TRACE
#define TRACE HMDLOG_BAK_TRACE
#undef HMDLOG_BAK_TRACE
#endif

#ifdef __cplusplus
}
#endif

#endif  // HDR_HMDLogger_h
