//
// Created by william on 2020/3/11.
//

#ifndef AUDIO_EFFECT_INCLUDE_AE_EXTRACTOR_DEF_H
#define AUDIO_EFFECT_INCLUDE_AE_EXTRACTOR_DEF_H
#include <string>
#include <unordered_map>
#include <vector>
#include "ae_algorithms_macros.h"

namespace mammon {

using FeatureID = size_t;

/**
     * @brief Describe what this feature is
     *
     */
struct FeatureDescriptor {
    /**
         * @brief Feature id to find feature
         *
         */
    FeatureID id;
    /**
         * @brief Sampling rate used in this feature
         *
         */
    size_t samplerate;
    /**
         * @brief Which unit this feature use
         *
         */
    std::string unit;
    /**
         * @brief The human-readable name of the feature
         *
         */
    std::string name;
};

/**
     * @brief Detected feature result
     *
     */
#if defined(BUILD_ASR_OFFLINE_EXTRACTOR) || defined(BUILD_ASR_ONLINE_EXTRACTOR)
struct Feature {
    float time;
    float duration;
    std::vector<float> values;
    std::string result;
};
#else
struct Feature {
    float time;
    float duration;
    std::vector<float> values;
};
#endif

using FeatureSet = std::unordered_map<FeatureID, std::vector<Feature>>;

enum class ExtractorType {
    F0Detection = 0,
    OnsetDetection,
    SpectrumDisplay,
    VolumnDetection,
    EventDetection,
    VoiceActivityDetection,
    BeatTracking,
    BeatTrackingOffline,
    Music2VibesVideoModel,
    Music2VibesMatchModel,
    NNVAD,
    Loudness,
    KWS_CHN,
    KWS_ENG,
    KWS_CHN_PINYIN,
    AED,
    ASR_OFFLINE,
    ASR_ONLINE,
    KWS_ENG_FRUIT,
#ifdef ENABLE_TOB_CV_AUTH_INTERNAL
    BYPASS = 100,
#endif
};

/**
     * @brief Get the map which mapping names to ids of featurees
     *
     * @return const std::unordered_map<std::string, FeatureID>&
     */
extern const std::unordered_map<std::string, FeatureID>& getFeatureName2IDMap();

}  // namespace mammon

// Feature IDs
// Important!!: Should also add a mapping in getFeatureName2IDMap
#define AE_FEATURE_ID_VOLUME                        1
#define AE_FEATURE_ID_F0                            2
#define AE_FEATURE_ID_SPECTRUM                      3
#define AE_FEATURE_ID_EVENT_DETECTION               4
#define AE_FEATURE_ID_BEAT_TRACKING                 5
#define AE_FEATURE_ID_BEAT_TRACKING_OFFLINE_OVERALL 6
#define AE_FEATURE_ID_MUSIC2VIBES_VIDEO_MODEL       7
#define AE_FEATURE_ID_MUSIC2VIBES_MATCH_MODEL       8
#define AE_FEATURE_ID_GLOBAL_LOUDNESS               9
#define AE_FEATURE_ID_GLOBAL_PEAK                   10

#define AE_FEATURE_ID_VOICE_ACTIVITY_DETECTION         11
#define AE_FEATURE_ID_VOICE_ACTIVITY_DETECTION_OVERALL 12

#define AE_FEATURE_ID_NNVAD         13
#define AE_FEATURE_ID_NNVAD_OVERALL 14

#define AE_FEATURE_ID_ONSET         15
#define AE_FEATURE_ID_ONSET_OVERALL 16

#define AE_FEATURE_ID_KWS 17
#define AE_FEATURE_ID_AED 18

#define AE_FEATURE_ID_SHORTTERM_LOUDNESS 19
#define AE_FEATURE_ID_MOMENTARY_LOUDNESS 20

#define AE_FEATURE_ID_ASR_OFFLINE 21
#define AE_FEATURE_ID_ASR_ONLINE 22

#define AE_FEATURE_ID_AED_STATISTIC 23
#define AE_FEATURE_ID_VOICE_ACTIVITY_DETECTION_STATISTIC 24

// Feature names:
#define AE_FEATURE_NAME_ONSET                            "onset"
#define AE_FEATURE_NAME_ONSET_OVERALL                    "onset-overall"
#define AE_FEATURE_NAME_VOLUME                           "volume"
#define AE_FEATURE_NAME_F0                               "f0"
#define AE_FEATURE_NAME_SPECTRUM                         "spectrum"
#define AE_FEATURE_NAME_EVENT_DETECTION                  "event-detection"
#define AE_FEATURE_NAME_BEAT_TRACKING                    "beat-tracking"
#define AE_FEATURE_NAME_BEAT_TRACKING_OFFLINE_OVERALL    "beat-tracking-offline-overall"
#define AE_FEATURE_NAME_MUSIC2VIBES_VIDEO_MODEL          "music2vibes-video-model"
#define AE_FEATURE_NAME_MUSIC2VIBES_MATCH_MODEL          "music2vibes-match-model"
#define AE_FEATURE_NAME_GLOBAL_LOUDNESS                  "global-loudness"
#define AE_FEATURE_NAME_GLOBAL_PEAK                      "global-peak"
#define AE_FEATURE_NAME_VOICE_ACTIVITY_DETECTION         "voice-activity-detection"
#define AE_FEATURE_NAME_VOICE_ACTIVITY_DETECTION_OVERALL "voice-activity-detection-overall"
#define AE_FEATURE_NAME_NNVAD                            "nnvad"
#define AE_FEATURE_NAME_NNVAD_OVERALL                    "nnvad-overall"

#define AE_FEATURE_NAME_KWS                               "kws"
#define AE_FEATURE_NAME_AED                               "aed"
#define AE_FEATURE_NAME_ASR_OFFLINE                       "asr-offline"
#define AE_FEATURE_NAME_ASR_ONLINE                        "asr-online"

// Extractor Type IDs
#define F0_DETECTION_TYPE_ID             0
#define ONSET_DETECTION_TYPE_ID          1
#define SPECTRUM_DISPLAY_TYPE_ID         2
#define VOLUMN_DETECTION_TYPE_ID         3
#define EVENT_DETECTION_TYPE_ID          4
#define VOICE_ACTIVITY_DETECTION_TYPE_ID 5

#endif  // AUDIO_EFFECT_INCLUDE_AE_EXTRACTOR_DEF_H
