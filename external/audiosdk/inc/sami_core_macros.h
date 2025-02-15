#ifndef SAMI_CORE_MACROS
#define SAMI_CORE_MACROS

// this file used to generate sami_core_macros.h which included in pipeline demo, so that demo can build with macros
// you can use cmake config_file() to generate header, and then #include "the_generated_header.h"

/* #undef ENABLE_SAMI_CORE_TEST */
#define SAMI_CORE_USING_IESAPPLOG
/* #undef SAMI_CORE_BUILD_JAVA_JNI */
/* #undef ENABLE_SAMI_CORE_TEST */
/* #undef SAMICORE_BUILD_SHARED_LIB */
#define ENABLE_BUSINESS_TTPLAYER
#define BUILD_AUDIO_CLEANER
#define BUILD_AUDIO_EXCITER
#define BUILD_AUDIO_EQ
#define BUILD_PITCH_TEMPO
#define BUILD_AUDIO_REVERB
#define BUILD_AUDIO_DELAY
#define BUILD_AUDIO_CHER_EFFECT
#define BUILD_AEC
#define BUILD_NS
#define BUILD_AGC
#define BUILD_AUDIO_COMPRESSOR
#define BUILD_LOUDNORM
/* #undef ENABLE_KARAOKE */
#define BUILD_AUDIO_BIQUAD_FILTER
#define BUILD_AUDIO_EFFECT_FILTER
#define BUILD_AUDIO_LOUDNESS
#define BUILD_ONSET_DETECTION
#define BUILD_SPATIAL_AUDIO
#define BUILD_RESONANCE_AUDIO
#define BUILD_STEREO_PANNING
#define BUILD_STEREO_WIDEN
#define BUILD_AUDIO_FADING
#define BUILD_RNNOISE
#define BUILD_RNNOISE_48K_MODEL
/* #undef BUILD_RNNOISE_16K_MODEL */
#define BUILD_VAD
/* #undef ENABLE_VAD_S2S */
#define BUILD_NNVAD
#define BUILD_SING_SCORING
#define BUILD_SPECTRUM_DISPLAY
/* #undef BUILD_CHORUS_DETECTION */
#define BUILD_AUDIO_SCRATCHING
#define BUILD_HQFADER
#define BUILD_VOCODER
#define BUILD_MEGAPHONE
#define BUILD_SAMPLER
#define BUILD_SEGMENT_FINDER
/* #undef BUILD_AUDIO_PREPROCESS */
#define BUILD_RETARGET
/* #undef BUILD_DUCKER */
#define BUILD_MDSP_EFFECT
#define BUILD_BEAT_TRACKING
/* #undef BUILD_AUTO_VOLUME */
#define BUILD_PITCH_SHIFTER
#define BUILD_ONLINE_LOUDNORM
/* #undef ENABLE_LOUDNORM_SKIP_CATCH */
#define BUILD_SPRING_FESTIVAL
/* #undef BUILD_TIME_SCALER */
#define BUILD_KWS_EXTRACTOR
#define BUILD_AED_EXTRACTOR
/* #undef ENABLE_AED_S2S */
/* #undef BUILD_ASR_OFFLINE_EXTRACTOR */
#define ENABLE_AE_ENGINE
#define ENABLE_UTILS
/* #undef ENABLE_CMD_TESTING */
/* #undef ENABLE_TESTING */
/* #undef BUILD_TESTING_LIBRARY */
/* #undef ENABLE_ASAN */
/* #undef CODE_COVERAGE */
/* #undef REDUCE_SIZE */
/* #undef BUILD_ANDROID_JNI */
/* #undef ENABLE_EMSCRIPTEN_MAIN_TESTING */
/* #undef BUILD_WASM_JS */
#define ENABLE_MAMMON_ENGINE
/* #undef BUILD_DOCUMENTS */
/* #undef BUILD_MAMMON_SDK_TESTS */
/* #undef BUILD_MAMMON_SDK_SAMPLES */
/* #undef BUILD_TESTING_TOOLS */
/* #undef MAMMON_DEBUG */
/* #undef USE_FFMPEG */
#define BUILD_WITH_DEPRECATED_CODE
/* #undef USE_SPDLOG */
#define BUILD_SPATIAL_AUDIO
/* #undef MAMMON_ENGINE_BUILD_SPATIAL_AUDIO */
/* #undef BUILD_DAW_CORE */
/* #undef BUILD_C_API */
/* #undef ENABLE_HIGH_PRIORITY */
/* #undef ENABLE_DEVICE_INPUT */
/* #undef USE_TTFFMPEG */
#define USE_SAMI
/* #undef ENABLE_AAUDIO_BACKEND */
/* #undef ENABLE_AUDIOUNIT_BACKEND */
#define ENABLE_STREAM_SOURCE_NODE
#define ENABLE_MAMMON_NODE_CACHE
#define ENABLE_MULTIPORT_IO
#define ENABLE_FILE_SOURCE_NODE_RESAMPLE
#define ENABLE_MAMMON_AUDIO_IO_MIDI
#define ENABLE_AUDIO_BACKEND
/* #undef ENABLE_BINARY_CONTEXT */
#define ENABLE_ENCRYPT
/* #undef ENABLE_TOB_CV_AUTH */
/* #undef ENABLE_TOB_CV_AUTH_INTERNAL */
#define SAMI_CORE_USING_NET
/* #undef SAMI_CORE_GET_TOKEN */
/* #undef SAMI_CORE_USING_ONLINE_AUTH */
/* #undef SAMI_CORE_USING_OFFLINE_AUTH */
#define SAMI_CORE_USING_SERVER_API
#define SAMI_CORE_USING_SERVER_TTS
#define SAMI_CORE_USING_SERVER_ASR
#define SAMI_CORE_USING_SERVER_BEAT_TRACKING
#define SAMI_CORE_USING_SERVER_MSS
#define SAMI_CORE_USING_SERVER_MUSIC_TAGGING
#define SAMI_CORE_USING_SERVER_CHORUS
#define SAMI_CORE_USING_SERVER_MUSIC_RETARGET
#define SAMI_CORE_USING_SERVER_MIDI
#define SAMI_CORE_USING_SERVER_SPEECH_DISFLUENCY
#define SAMI_CORE_USING_SERVER_LYRICS_ALIGNMENT
/* #undef SAMI_CORE_USING_SERVER_SPEECHTOSONG */
#define SAMI_CORE_USING_SERVER_WS_API
#define SAMI_CORE_USING_SERVER_WS_ASR
#define SAMI_CORE_USING_SERVER_WS_TTS
#define SAMI_CORE_USING_SERVER_WS_BYTETUNER
#define ENABLE_SAMI_CORE_EXTRACTOR
#define ENABLE_SAMI_CORE_CONTEXT_PROCESSOR
/* #undef ENABLE_SAMI_CORE_PROCESSOR */
/* #undef ENABLE_SAMI_CORE_TIME_SCALER */
#define ENABLE_SAMI_CORE_NNAEC
#define ENABLE_SAMI_CORE_TIME_ALIGN
/* #undef ENABLE_SAMI_CORE_MUTI_TIME_ALIGN */
/* #undef ENABLE_SAMI_CORE_RNNOISE16K */
/* #undef ENABLE_SAMI_CORE_RNNOISE48K */
#define ENABLE_SAMI_CORE_TIME_TCN_DENOISE
#define ENABLE_SAMI_CORE_DENOISE_V2
#define ENABLE_SAMI_CORE_RTC_DENOISE
/* #undef ENABLE_TOB_CH_STRIP */
/* #undef ENABLE_3D_AUDIO */
#define ENABLE_SAMI_CORE_TUNE_TO_TARGET
/* #undef ENABLE_SPEECH_RECOGNITION */
/* #undef SAMI_CORE_RACK_DEMO */
/* #undef ENABLE_SAMI_CORE_NNAEC_MIC_SELECTION */
/* #undef ENABLE_PLAYER_LOUDNORM2 */
#define ENABLE_MDSP_SINGLE_PROCESSOR_EFFECT
/* #undef ENABLE_SAMI_CORE_MSS */
#define ENABLE_MUL_DIM_SING_SCORING
#define BUILD_AUDIO_SCRATCHING
/* #undef ENABLE_SAMI_CORE_KWS */
/* #undef ENABLE_SAMI_CORE_AUDIOFADING */
#define ENABLE_SAMI_CORE_NNAEC_V3
/* #undef ENABLE_SAMI_CORE_DENOISE_V3 */
#define ENABLE_SAMI_CORE_LOUDNORM3
/* #undef SAMI_CORE_USING_AUDIO_CODEC */
/* #undef ENABLE_SAMI_CORE_AUDIO_RETARGET */
/* #undef ENABLE_SAMI_CORE_AUDIO_YGGDRASIL_V0_5 */
/* #undef ENABLE_SAMI_CORE_AUDIO_METRICS */
/* #undef ENABLE_SAMI_CORE_AUDIO_METRICS_V2 */
#define SAMI_CORE_USING_COMMON_ENGINE_EXECUTOR
/* #undef SAMI_CORE_USING_COMMON_ENGINE_EXECUTOR_TOB */
/* #undef ENABLE_SAMI_CORE_DUMP_WAV */
/* #undef ENABLE_SAMI_CORE_CE_AEC */
/* #undef ENABLE_SAMI_CORE_LOUDNESS_STRATEGY */
/* #undef ENABLE_GET_DEVICE_ABILITY */
/* #undef ENABLE_SAMI_CORE_PANORAMA */
#define BUILD_TTS_MANAGER
/* #undef SAMI_CORE_USING_PLAY_TTS */
/* #undef ENABLE_SAMI_CORE_WS_VC */
#endif  // SAMI_CORE_MACROS
