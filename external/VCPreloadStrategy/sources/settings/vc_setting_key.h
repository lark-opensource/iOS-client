//
// Created by 黄清 on 3/16/21.
//

#ifndef PRELOAD_VC_SETTING_KEY_H
#define PRELOAD_VC_SETTING_KEY_H

#include "vc_base.h"

VC_NAMESPACE_BEGIN

namespace VCSettingKey {
extern const int VOD;
extern const int MDL;

extern const char *Module_VOD;
extern const char *Module_MDL;

namespace VodKey {
extern const char *Hardware;
extern const char *ByteVC1;
extern const char *PersonalizedGlobalParams;
extern const char *PersonalizedReBufferParams;
extern const char *PersonalizedStartupParams;
extern const char *PersonalizedPreloadParams;
extern const char *OptionAutoResumeTaskWhenPlay;
extern const char *OptionPauseIOWhenRequestEnd;
extern const char *OptionEnableUseCacheFlag;
extern const char *OptionEnableContextForPlayer;
extern const char *OptionEnableRangeStartMsg;
extern const char *OptionBackgroundCode;
extern const char *OptionBackgroundTTL;
extern const char *OptionPlayRecordPersistentNum;
extern const char *OptionBandwidthSampleRate;
} // namespace VodKey

namespace MDLKey {}

} // namespace VCSettingKey

VC_NAMESPACE_END

#endif // PRELOAD_VC_SETTING_KEY_H
