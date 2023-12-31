//
//  cme_type_defs.h
//  mammon_engine
//

#ifndef mammon_engine_cme_type_defs_h
#define mammon_engine_cme_type_defs_h

#include <stddef.h>
#include <stdint.h>

#include "mammon_engine_defs.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef int64_t CMETransportTime;

typedef enum
{
    CMEEncoderFileFormatWave
} CMEEncoderFileFormat;

typedef struct
{
    CMEEncoderFileFormat format;
} CMEEncoderFormat;

typedef enum
{
    CMETransportStatePreparing,  ///< 准备开始播放
    CMETransportStatePlaying,    ///< 播放中
    CMETransportStateStopping,   ///< 停止中
    CMETransportStateStopped,    ///< 已经停止播放
    CMETransportStatePaused,     ///< 暂停
    CMETransportStateRecording   ///< 录音中
} CMETransportState;

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_type_defs_h */
