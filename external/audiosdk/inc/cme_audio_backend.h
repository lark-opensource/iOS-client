//
//  cme_audio_backend.h
//  mammon_engine
//

#ifndef mammon_engine_cme_audio_backend_h
#define mammon_engine_cme_audio_backend_h

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum
{
    CMEAudioBackendCallbackStatusOK,
    CMEAudioBackendCallbackStatusUnderRun,
    CMEAudioBackendCallbackStatusUnbind
} CMEAudioBackendCallbackStatus;

typedef enum
{
    CMEDeviceMesageDeviceDisconnected,
    CMEDeviceMesageDeviceConnected,
    CMEDeviceMesageSampleRateChanged,
    CMEDeviceMesageDeviceChanged,
    CMEDeviceMesageStreamingStarted,
    CMEDeviceMesageStreamingStopped,
    CMEDeviceMesageChangeRenderContext,
    CMEDeviceMesageAcquireGraph
} CMEDeviceMesage;

typedef enum
{
    CMEDeviceStatusOK,
    CMEDeviceStatusUnSupported
} CMEDeviceStatus;

typedef enum
{
    CMEBackendTypeRealtime,
    CMEBackendTypeOffline
} CMEBackendType;

typedef struct CMEAudioBackendImpl CMEAudioBackend;
// typedef struct CMEDummyBackendImpl CMEDummyBackend;
// typedef struct CMEFileBackendImpl CMEFileBackend;

typedef CMEAudioBackendCallbackStatus(*CMEAudioBackendIOCallback)(CMEAudioBackend*, float*, size_t, size_t);

typedef CMEAudioBackendCallbackStatus(*CMEAudioBackendMessageCallback)(CMEAudioBackend*, CMEDeviceMesage, void*);

void mammon_backend_createDefaultBackend(CMEAudioBackend**inoutBackend, size_t sample_rate);

void mammon_backend_destroy(CMEAudioBackend**inoutBackend);

// int32_t mammon_backend_createFileBackend(size_t sample_rate, sizze_t channels);
// int32_t mammon_backend_createDummyBackend(size_t sample_rate);

const char * mammon_backend_getName(CMEAudioBackend *backend);

CMEDeviceStatus mammon_backend_setSampleRate(CMEAudioBackend *backend, size_t fs);

size_t mammon_backend_getSampleRate(CMEAudioBackend *backend);

// --- Input Settings --- //
void mammon_backend_setInputCallback(CMEAudioBackend *backend, CMEAudioBackendIOCallback callback);

void mammon_backend_removeInputCallback(CMEAudioBackend *backend);

void mammon_backend_setInputEnabled(CMEAudioBackend *backend, bool enabled);

bool mammon_backend_inputEnabled(CMEAudioBackend *backend);

size_t mammon_backend_getInputSampleRate(CMEAudioBackend *backend);

size_t mammon_backend_getInputChannelNum(CMEAudioBackend *backend);

CMEDeviceStatus mammon_backend_setInputChannelNum(CMEAudioBackend *backend, size_t num);

// --- Output Settings --- //
void mammon_backend_setOutputCallback(CMEAudioBackend *backend, CMEAudioBackendIOCallback callback);

void mammon_backend_removeOutputCallback(CMEAudioBackend *backend);

void mammon_backend_setOutputEnabled(CMEAudioBackend *backend, bool enabled);

// bool mammon_backend_outputEnabled(CMEAudioBackend *backend);

size_t mammon_backend_getOutputSampleRate(CMEAudioBackend *backend);

size_t mammon_backend_getOutputChannelNum(CMEAudioBackend *backend);

CMEDeviceStatus mammon_backend_setOutputChannelNum(CMEAudioBackend *backend, size_t num);

void mammon_backend_setDeviceMessageCallback(CMEAudioBackend *backend, CMEAudioBackendMessageCallback callback);

void mammon_backend_removeDeviceMessageCallback(CMEAudioBackend *backend);

CMEBackendType mammon_backend_getType(CMEAudioBackend *backend);

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_audio_backend_h */
