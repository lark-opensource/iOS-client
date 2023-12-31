
//
//  bef_effect_algorithm_api.h
//  Pods
//
//  Created by liziyu on 2019/6/12.
//

#ifndef bef_effect_algorithm_api_h
#define bef_effect_algorithm_api_h
#include "bef_effect_public_define.h"
#include <stdbool.h>

typedef void* bef_bingo_VideoMontageHandle;

typedef struct bef_bingo_VideoMontage_BeatsParams
{
    int veBeatsNum;
    int downBeatsNum;
    bool veBeatsOnline;
    bool downBeatsWithStrength;
    const float* veBeatsTime;
    const float* veBeatsStrength;
    const float* downBeatsTime;
    const float* downBeatsStrength;
    const int* downBeatsType;
} bef_bingo_VideoMontage_BeatsParams;

typedef enum bef_bingo_VideoMontage_RawDataType {
    bef_bingo_VideoMontage_kImage,
    bef_bingo_VideoMontage_kVideo
} bef_bingo_VideoMontage_RawDataType;



typedef struct bef_bingo_VideoMontage_VideoParams
{
    int width;
    int height;
    float fps;
    float sampleFps;
    float duration;
    bef_bingo_VideoMontage_RawDataType type;
} bef_bingo_VideoMontage_VideoParams;

typedef enum bef_bingo_VideoMontage_OutPhotoEffect {
    bef_bingo_VideoMontage_kNull,
    bef_bingo_VideoMontage_kZoomIn,
    bef_bingo_VideoMontage_kZoomOut
} bef_bingo_VideoMontage_OutPhotoEffect;

typedef struct bef_bingo_beats_file_parse_result
{
    float *time;
    unsigned long timeLength;
    float *energy;
    unsigned long energyLength;
    int *value;
    unsigned long valueLength;
}bef_bingo_beats_file_parse_result;


typedef struct bef_bingo_mat
{
    unsigned char* data;
    unsigned int width;
    unsigned int height;
    unsigned int channels;
    unsigned long stride;
    unsigned int alignment;
} bef_bingo_mat;


typedef enum bef_bingo_ColorFormatType
{
    bef_kColorFormat_RGBA8888 = 0,
    bef_kColorFormat_BGRA8888 = 1,
    bef_kColorFormat_BGR888 = 2,
    bef_kColorFormat_RGB888 = 3,
    bef_kColorFormat_NV12 = 4,
    bef_kColorFormat_GRAY = 5,
    bef_kColorFormat_Unknown = 255,
} bef_bingo_ColorFormatType;

typedef enum bef_bingo_VideoMontage_ProcessMode
{
    bef_bingo_VideoMontage_kTransOnly,  // only output video transitions
    bef_bingo_VideoMontage_kVideoClip   // online version
} bef_bingo_VideoMontage_ProcessMode;

typedef enum bef_bingo_VideoMontage_ModelType
{
    bef_bingo_VideoMontage_kModelAfterEffect,
    bef_bingo_VideoMontage_kModelVideoCls,
    bef_bingo_VideoMontage_kModelVideoTrans
} bef_bingo_VideoMontage_ModelType;

typedef enum bef_bingo_VideoMontage_TransitionsType
{
    bef_bingo_VideoMontage_kTransNull       = 0,
    bef_bingo_VideoMontage_kTransDissolve   = 1,
    bef_bingo_VideoMontage_kTransBlack      = 2,     // Suddenly turned black
    bef_bingo_VideoMontage_kTransWhite      = 3,     // Suddenly turned white
    bef_bingo_VideoMontage_kTransZoomOut    = 4,
    bef_bingo_VideoMontage_kTransZoomIn     = 5,
} bef_bingo_VideoMontage_TransitionsType;

typedef enum bef_bingo_VideoMontage_MusicEmotion
{
    bef_bingo_VideoMontage_kMusicEmotionNull = 0,
    bef_bingo_VideoMontage_kMusicSorrow      = 1,
    bef_bingo_VideoMontage_kMusicExcited     = 2,
    bef_bingo_VideoMontage_kMusicHappy       = 3,
    bef_bingo_VideoMontage_kMusicRomantic    = 4,
    bef_bingo_VideoMontage_kMusicAngry       = 5,
} bef_bingo_VideoMontage_MusicEmotion;

typedef enum bef_bingo_VideoMontage_MusicStyle
{
    bef_bingo_VideoMontage_kMusicStyleNull   = 0,
    bef_bingo_VideoMontage_kMusicElectronic  = 1,
    bef_bingo_VideoMontage_kMusicRnB         = 2,
    bef_bingo_VideoMontage_kMusicHiphop      = 3,
    bef_bingo_VideoMontage_kMusicClassical   = 4,
    bef_bingo_VideoMontage_kMusicPop         = 5,
    bef_bingo_VideoMontage_kMusicRock        = 6,
} bef_bingo_VideoMontage_MusicStyle;

typedef struct bef_bingo_VideoMontage_TransRecommenderParams
{
    bef_bingo_VideoMontage_MusicEmotion musicEmotion;
    bef_bingo_VideoMontage_MusicStyle musicStyle;
} bef_bingo_VideoMontage_TransRecommenderParams;

typedef struct bef_bingo_VideoMontage_Output
{
    int videoId;
    float beginTime;
    float endTime;
    float playDuration;
    float rotateAngle;
    const char* videoKey;
    bef_bingo_VideoMontage_RawDataType type;
    bef_bingo_VideoMontage_OutPhotoEffect effect;
    bef_bingo_VideoMontage_TransitionsType transType;  // transitions' type
    float transTime;                                   // transitions' duration
} bef_bingo_VideoMontage_Output;

BEF_SDK_API
int bef_bingo_VideoMontage_CreateHandle(bef_bingo_VideoMontageHandle* out);

BEF_SDK_API
int bef_bingo_VideoMontage_init(bef_bingo_VideoMontageHandle handle,
                                bef_resource_finder finder,
                                bef_bingo_VideoMontage_ModelType modelType);

BEF_SDK_API
int bef_bingo_VideoMontage_init_with_path(bef_bingo_VideoMontageHandle handle,
                                          const char assetModelPath[],
                                          bef_bingo_VideoMontage_ModelType modelType);

BEF_SDK_API
int bef_bingo_VideoMontage_setBeatsFromParams(bef_bingo_VideoMontageHandle handle,
                                              bef_bingo_VideoMontage_BeatsParams* params);

BEF_SDK_API
int bef_bingo_VideoMontage_setMotionRatios(bef_bingo_VideoMontageHandle handle,
                                       float optRatio,
                                       float leftBound,
                                       float rightBound);
BEF_SDK_API
int bef_bingo_VideoMontage_setMusicTime(bef_bingo_VideoMontageHandle handle,float startTime,float duration);


BEF_SDK_API
int bef_bingo_VideoMontage_setBeatsPartitionMode(bef_bingo_VideoMontageHandle handle,
                                                 int mode);

BEF_SDK_API
int bef_bingo_VideoMontage_setMusicCropRatio(bef_bingo_VideoMontageHandle handle,
                                             float ratio);

BEF_SDK_API
bool bef_bingo_VideoMontage_insertVideo(bef_bingo_VideoMontageHandle handle,
                                        bef_bingo_VideoMontage_VideoParams* params,
                                        int pos,
                                        const char videoKey[]);

BEF_SDK_API
bool bef_bingo_VideoMontage_moveVideo(bef_bingo_VideoMontageHandle handle,
                                      int fromPos,
                                      int toPos);

BEF_SDK_API
bool bef_bingo_VideoMontage_deleteVideo(bef_bingo_VideoMontageHandle handle,
                                        int pos);
BEF_SDK_API
bool bef_bingo_VideoMontage_rotateVideo(bef_bingo_VideoMontageHandle handle,
                                    float rotateAngle,
                                    int pos);


BEF_SDK_API
bool bef_bingo_VideoMontage_processFramePairWithTime(
                                                     bef_bingo_VideoMontageHandle handle,
                                                     bef_bingo_mat* image,
                                                     bef_bingo_mat* imageNext,
                                                     bef_bingo_ColorFormatType colorfmt,
                                                     float time,
                                                     const char videoKey[]);

BEF_SDK_API
bool bef_bingo_VideoMontage_processFramePair(bef_bingo_VideoMontageHandle handle,
                                             bef_bingo_mat* image,
                                             bef_bingo_mat* imageNext,
                                             const char videoKey[]);

BEF_SDK_API
int bef_bingo_VideoMontage_getVideoNum(bef_bingo_VideoMontageHandle handle);


BEF_SDK_API
bef_bingo_VideoMontage_Output* bef_bingo_VideoMontage_solve(
                                                            bef_bingo_VideoMontageHandle handle);

BEF_SDK_API
bef_bingo_VideoMontage_Output* bef_bingo_VideoMontage_randomSolve(
                                                                  bef_bingo_VideoMontageHandle handle);

BEF_SDK_API
bef_bingo_VideoMontage_Output* bef_bingo_VideoMontage_randomSolveDisableZoom(
        bef_bingo_VideoMontageHandle handle,
        bool disableZoom);

BEF_SDK_API
bool bef_bingo_VideoMontage_deleteOutput(bef_bingo_VideoMontageHandle handle, bef_bingo_VideoMontage_Output* output);

BEF_SDK_API
int bef_bingo_VideoMontage_releaseHandle(bef_bingo_VideoMontageHandle handle);

BEF_SDK_API
bool bef_bingo_VideoMontage_parseBeatsFile(const char* path,bef_bingo_beats_file_parse_result *result);

BEF_SDK_API
int bef_bingo_VideoMontage_saveInterimScoresToFile(bef_bingo_VideoMontageHandle handle, const char* filePath);

BEF_SDK_API
int bef_bingo_VideoMontage_checkScoreFileIntegrity(bef_bingo_VideoMontageHandle handle, const char* filePath);

BEF_SDK_API 
void bef_bingo_VideoMontage_relese_parsed_result(bef_bingo_beats_file_parse_result* result);

/**
 * @brief Compute and store video cls feats for a frame in video or an image.
 * @param [in] image: input image
 * @param [in] time: timestamp of frame, 0 for iamge
 * @param [in] videoKey: identity key of the video/image
 * @return If succeed return true, otherwise return false
 */
BEF_SDK_API
bool bef_bingo_VideoMontage_videoClsFrameWithTime(bef_bingo_VideoMontageHandle handle,
                                                  bef_bingo_mat* image,
                                                  bef_bingo_ColorFormatType colorfmt,
                                                  float time,
                                                  const char videoKey[]);
/**
 * @brief Set the transitions recommender from params
 * @return If succeed return 0, otherwise return -1
 */
BEF_SDK_API
int bef_bingo_VideoMontage_setTransRecParams(bef_bingo_VideoMontageHandle handle,
                                             bef_bingo_VideoMontage_TransRecommenderParams* params);
/**
 * @brief Set the process mode parameter
 * @return If succeed return 0, otherwise return -1
 */
BEF_SDK_API
int bef_bingo_VideoMontage_setProcessMode(bef_bingo_VideoMontageHandle handle,
                                          bef_bingo_VideoMontage_ProcessMode mode);
/**
 * @brief Set the randomness degree in video trans
 * @param [in] rand: range is [0, 1] where 0 means no randomness. Default value  is 0.5
 * @return If succeed return 0, otherwise return -1
 */
BEF_SDK_API
int bef_bingo_VideoMontage_setVideoTransRand(bef_bingo_VideoMontageHandle handle,
                                             float rand);

#endif /* bef_effect_algorithm_api_h */



