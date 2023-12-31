// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_WRAPPER_H
#define KRYPTON_EFFECT_WRAPPER_H

#include <pthread.h>
#include <stdio.h>

#include <string>

#include "canvas/gpu/gl_context.h"
#include "krypton_effect_message_channel.h"
#include "krypton_effect_output_struct.h"
#include "krypton_effect_pfunc.h"
#include "krypton_effect_resource_downloader.h"

namespace lynx {
namespace canvas {
namespace me {

enum Flags {
  FRONT = 0,
  BACK = 1,
  EXACT = 2,
  VIDEO = 4,
  AUDIO = 8,
  BEAUTIFY = 16,
  LANDSCAPE = 32,
  LANDSCAPE_RIGHT = 64,
  HGMOJI = 128,
  HAND = 256,
  MATTING = 512,
  HAIRPARSER = 1024,
  PLANETRACK = 2048,
  SKELETON = 4096,
  STICKER = 8192,
};

enum Rotation : uint32_t {
  kRotationNone = 0,
  kRotationClockWise,
  kRotation180,
  kRotationCounterClockWise,

  kRotationNoneFlipX,
  kRotationClockWiseFlipX,
  kRotation180FlipX,
  kRotationCounterClockWiseFlipX,
};
}  // namespace me

enum EffectWrapperResult {
  EROK = 0,
  ERINVALID_HANDLER = -1,
  ERINVALID_PARAM = -2,
  ERINVALID_MSGCALLBACK = -3
};

#define kEFFECT_TAG_WHITEN "epm/frag/whiten"
#define kEFFECT_TAG_BLUR "epm/frag/blurAlpha"
#define kEFFECT_TAG_EYE "FaceDistortionEyeIntensity"
#define kEFFECT_TAG_CHEEK "FaceDistortionCheekIntensity"

struct stRoiInfo {
  int centerPosY;
  int centerPosX;
  int roiWidth;
  int roiHeight;
  float roiYaw;
  float roiPitch;
  float roiRoll;

  stRoiInfo() {
    centerPosX = -1;
    centerPosY = -1;
    roiWidth = -1;
    roiHeight = -1;
    roiYaw = 0.0f;
    roiPitch = 0.0f;
    roiRoll = 0.0f;
  }

  stRoiInfo(int posX, int posY, int width, int height, float yaw, float pitch,
            float roll) {
    centerPosX = posX;
    centerPosY = posY;
    roiWidth = width;
    roiHeight = height;
    roiYaw = yaw;
    roiPitch = pitch;
    roiRoll = roll;
  }

  stRoiInfo(stRoiInfo &roiInfo) {
    this->centerPosX = roiInfo.centerPosX;
    this->centerPosY = roiInfo.centerPosY;
    this->roiWidth = roiInfo.roiWidth;
    this->roiHeight = roiInfo.roiHeight;
    this->roiYaw = roiInfo.roiYaw;
    this->roiPitch = roiInfo.roiPitch;
    this->roiRoll = roiInfo.roiRoll;
  }
};

namespace effect {
class EffectWrapper : public std::enable_shared_from_this<EffectWrapper> {
 public:
  static char *GetSDKVerion();

  EffectWrapper(int width, int height, uint32_t algorithms);
  virtual ~EffectWrapper();

  void Init();
  bool Resume();
  bool Pause();
  // executing algorithms to process textures
  bool ProcessTexture(unsigned int tex_src, unsigned int tex_dst,
                      bef_rotate_type orientation, double time_stamp);
  bool GetFaceDetectResult(FaceInfo &res);
  bool GetSkeletonDetectResult(SkeletonInfo &res);
  bool GetHandDetectResult(HandInfo &res);

  // Multiple prop resources are combined into a composer resource package, and
  // each sub prop directory is organized in the form of a tree structure for
  // users to select specific props / special effects items. Multiple props /
  // special effects items can coexist / be mutually exclusive according to
  // rules
  int ComposerSetMode(int mode, int order_type);

  int ComposerSetNodes(const char *node_paths[], int node_num);

  int ComposerUpdateNode(const char *node_path, const char *node_tag,
                         float node_value);

 private:
  int width_{0};
  int height_{0};
  bool inited_{false};

  std::unique_ptr<GLContext> gl_context_;
  bef_effect_handle_t effect_handler_ = 0;

 private:
  EffectWrapper();
  // set resource path (beauty / thin face composer path)
  static void SetBundlePath(std::string &&bundle_path);
  // set algorithm resource path
  static void SetAlgorithmModelPath(std::string &&algorithm_model_path);
  // pass in the built-in resource path for initialization
  int Init(std::string model_path, std::string str_device_name, int width,
           int height, bool is_use_resource_finder = false,
           uint32_t algorithm_flag = 0xFFFF);
  static int SetExternalNewAlgorithm(std::shared_ptr<EffectWrapper>);
  // force face detection on
  int ForceDetectFace(bool force_detect);
  int SwitchFilter(std::string &left_filter_path,
                   std::string &right_filter_path, float position);
  int SetFilter(std::string &filter_name, float intensity);
  // set special effects / whether to use default face data
  int SwitchResource(std::string &res_name, bool without_face);
  // set thin face parameters
  int SetReshape(const char *reshape_name, float eye_intensity,
                 float cheek_intensity);
  int SetSticker(const char *sticker_path,
                 EffectMessageCallbackType effect_callback = nullptr);
  int RemoveSticker();
  int DownloadSticker(const char *sticker_id,
                      StickerDownloadCallbackType callback);
  // pause effect processing
  int OnPause();
  // restore effect processing
  int OnResume();
  // set the width and height of effect
  int SetWidthHeight(int width, int height);
  // executing algorithms to process textures
  int DoProcessTexture(unsigned int textureid_src, unsigned int textureid_dst,
                       bef_rotate_type orientation, double time_stamp,
                       stRoiInfo *p_roi_info = nullptr);
  void GetFaceDetectResult(bef_face_info &result);
  void GetSkeletonDetectResult(bef_skeleton_result &result);
  void GetSlamDetectResult(bef_slam_info *result);
  void GetHandDetectResult(bef_hand_info &result);

  // set gyro parameters
  int SetDeviceRotation(float *quart);
  // max memory cache value, uint MB
  int SetMaxMemcache(unsigned int max_mem_cache);
  int SetCameraDevicePosition(bef_camera_position position);
  int setBeauty(const char *ckpBeautyName, float fSmoothIntensity,
                float fWhiteIntensity, float fSharpIntensity);

  int ComposerReloadNodes(const char *node_paths[], int node_num);

  int ComposerAppendNodes(const char *nodes[], int node_num);

  int ComposerRemoveNodes(const char *node_paths[], int node_num);

  // set whether to use mock face data
  void SetMockFace(bool enable);

  void ProcessTouchEvent(float x, float y);
  void ProcessPanEvent(float x, float y, float dx, float dy, float factor);
  void ProcessLongPressEvent(float x, float y);
  void ProcessDoubleClickEvent(float x, float y);
  void ProcessTouchDownEvent(float x, float y, int type);
  void ProcessTouchUpEvent(float x, float y, int type);
  void ProcessScaleEvent(float scale, float factor);
  void ProcessRotationEvent(float rotation, float factor);
  int SendMessage(unsigned int msg_gype, long arg1, long arg2,
                  std::string arg3);

 public:
  // set the algorithm to be turned on
  uint32_t algorithms_;
  // external algorithm parameters
  bef_requirement requirement_;

 protected:
  int image_width_ = 0;
  int image_height_ = 0;
  pthread_mutex_t mutex_data_;

  std::unique_ptr<EffectMessageChannel> message_channel_;
  EffectMessageChannel *MessageChannel();

  bef_auxiliary_data default_aux_data_;
  bef_face_info default_face_detect_;
  bool without_face_ = false;
  bool force_detect_face_ = false;

  std::unique_ptr<EffectMessageCallbackType> sticker_msg_callback_;
};
}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif  // KRYPTON_EFFECT_WRAPPER_HKRYPTON_EFFECT_WRAPPER_H
