// Copyright 2021 The Lynx Authors. All rights reserved.

#include "krypton_effect_wrapper.h"

#include <pthread.h>

#include <cstring>
#include <string>
#include <vector>

#include "canvas/base/log.h"
#include "canvas/gpu/gl_surface.h"
#include "canvas/platform/camera_option.h"
#include "krypton_effect.h"
#include "krypton_effect_video_context.h"

#define REQ_PARAM_MOUTH_DUDU \
  0x4000000  // beep detection switch 0x4000000 = TT_MOBILE_MOUTH_POUT *
             // BEF_FACE_BASE_NUM

namespace lynx {
namespace canvas {
namespace effect {

class ScopedEffectGLContext {
 public:
  ScopedEffectGLContext(GLContext *ctx)
      : ctx_(ctx),
        origin_ctx_(GLContext::GetCurrent()),
        surface_(GLSurface::GetCurrent()) {
    ctx_->MakeCurrent(nullptr);
  }

  ~ScopedEffectGLContext() {
    if (origin_ctx_) {
      origin_ctx_->MakeCurrent(surface_);
    }
  }

 private:
  GLContext *ctx_;
  GLContext *origin_ctx_;
  GLSurface *surface_;
};

static int effectLogFunc(int logLevel, const char *msg) {
  switch (logLevel) {
    case IESEffectLogLevelError:
      KRYPTON_LOGE("[KryptonEffect] ") << msg;
      break;
    case IESEffectLogLevelWarn:
      KRYPTON_LOGW("[KryptonEffect] ") << msg;
      break;
    case IESEffectLogLevelInfo:
      KRYPTON_LOGI("[KryptonEffect] ") << msg;
      break;
    case IESEffectLogLevelDebug:
      KRYPTON_LOGV("[KryptonEffect] ") << msg;
      break;
    case IESEffectLogLevelVerbose:
      KRYPTON_LOGV("[KryptonEffect] ") << msg;
      break;
  }
  return BEF_RESULT_SUC;
}

char *EffectWrapper::GetSDKVerion() {
  static char version[1024] = {0};
#if TARGET_IPHONE_SIMULATOR
  KRYPTON_LOGE("TARGET_IPHONE_SIMULATOR, Do not support Effect now");
  return nullptr;
#endif

  DCHECK(effect::EffectLoaded());
  auto ret = effect::bef_effect_get_sdk_version_local(version, 1024);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("Get Effect SDK Error with ret = ") << ret;
    return nullptr;
  }

  return version;
}

EffectWrapper::EffectWrapper(int width, int height, uint32_t algorithms)
    : width_(width), height_(height), algorithms_(algorithms) {
  // Muse be early init
  pthread_mutex_init(&mutex_data_, nullptr);
  memset(&default_aux_data_, 0, sizeof(default_aux_data_));
  memset(&default_face_detect_, 0, sizeof(default_face_detect_));
}

// only in js thread
void EffectWrapper::Init() {
  KRYPTON_LOGI("effect wrapper init start");
  if (inited_) {
    return;
  }

  inited_ = true;
  if (!gl_context_) {
    gl_context_ = GLContext::CreateVirtual();
    gl_context_->Init();
  }

  ScopedEffectGLContext scope(gl_context_.get());
  // turn on effect log
  effect::bef_effect_add_log_to_local_func_with_key_local("Krypton",
                                                          effectLogFunc);

  // disable ttnet related capabilities of effect
  // If enabled, ensure that the current environment ttnet has been initialized;
  // otherwise, bef will be caused_effect_destroy block
  bool ttnet_switch = false;
  effect::bef_effect_config_ab_value_local("enable_ttnet_in_effect",
                                           &ttnet_switch, 0);
  // turn on the cohesive gyroscope capability of effect
  bool sensor_services_switch = true;
  effect::bef_effect_config_ab_value_local("enable_build_in_sensor_service",
                                           &sensor_services_switch, 0);
  // turn off effect_sensor_manager_use_package_name switch
  // (after using the effectPlatformSDK scheme, you can open）
  bool sensor_use_pkg_name = false;
  effect::bef_effect_config_ab_value_local(
      "effect_sensor_manager_use_package_name", &sensor_use_pkg_name, 0);

  bef_effect_result_t ret = effect::bef_effect_create_local(&effect_handler_);
  if (effect_handler_ == 0 || ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] create effect handler failed: ") << ret;
    return;
  }
  effect::bef_effect_set_width_height_local(effect_handler_, width_, height_);
  effect::bef_effect_set_buildChain_flag_local(effect_handler_, true);

  uint64_t required_flags = 0;
  uint64_t required_params = 0;
  if (algorithms_ & EffectAlgorithms::kEffectFace) {
    required_flags |= BEF_REQUIREMENT_FACE_DETECT;
  }

  if (algorithms_ & EffectAlgorithms::kEffectSkeleton) {
    required_flags |= BEF_REQUIREMENT_SKELETON2;
  }

  if (algorithms_ & EffectAlgorithms::kEffectHand) {
    required_flags |= BEF_REQUIREMENT_HAND_BASE;
    required_params =
        required_params | ALGORITHM_PARAM_HAND | ALGORITHM_PARAM_HAND_KEYPOINT;
  }

#ifdef __ANDROID__
  const char *device = "Android";
#elif OS_IOS
  const char *device = "iOS";
#endif
  bef_resource_finder finder = reinterpret_cast<bef_resource_finder>(
      EffectResourceDownloader::Instance()->GetResourceFinder(effect_handler_));
  ret = bef_effect_init_with_resource_finder_local(effect_handler_, width_,
                                                   height_, finder, device);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] effect wrapper init fail, ret = ") << ret;
    return;
  }

  ret = effect::bef_effect_set_external_new_algorithm_local(
      effect_handler_, {required_flags, required_params});

  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] effect wrapper set algorithm fail: ") << ret;
    return;
  }
}

bool EffectWrapper::Pause() {
  if (!effect_handler_) {
    KRYPTON_LOGE("effect wrapper not ready");
    return false;
  };

  effect::bef_effect_onPause_local(effect_handler_, BEF_PAUSE_TYPE_ALL);

  return true;
}

bool EffectWrapper::Resume() {
  if (!effect_handler_) {
    KRYPTON_LOGE("effect wrapper not ready");
    return false;
  };

  effect::bef_effect_onResume_local(effect_handler_, BEF_PAUSE_TYPE_ALL);
  return true;
}

bool EffectWrapper::ProcessTexture(unsigned int tex_src, unsigned int tex_dst,
                                   bef_rotate_type orientation,
                                   double time_stamp) {
  if (!effect_handler_) {
    KRYPTON_LOGE("effect wrapper not ready");
    return false;
  };

  ScopedEffectGLContext scope(gl_context_.get());
  bef_effect_result_t ret;
  ret = effect::bef_effect_set_orientation_local(effect_handler_, orientation);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("bef_effect_set_orientation failed, ret = ") << ret;
    return false;
  }

  bef_src_texture texture = {
      .index = tex_src, .width = width_, .height = height_};
  bef_algorithm_param param = {.timeStamp = time_stamp};
  ret = effect::bef_effect_algorithm_multi_texture_with_params_local(
      effect_handler_, &texture, 1, &param);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("bef_effect_algorithm_multi_texture_with_params_local failed")
        << ret;
    return false;
  }

  if (algorithms_ & EffectAlgorithms::kEffectBeautify) {
    ret = effect::bef_effect_process_texture_local(effect_handler_, tex_src,
                                                   tex_dst, time_stamp);

    if (ret != BEF_RESULT_SUC) {
      KRYPTON_LOGE("bef_effect_process_texture_local failed, ret: ") << ret;
      return false;
    }
  }

  return true;
}

bool EffectWrapper::GetFaceDetectResult(FaceInfo &res) {
  if (!effect_handler_) {
    KRYPTON_LOGE("effect wrapper not ready");
    return false;
  };

  bef_face_info face_info_;
  bef_effect_result_t ret;
  ret = effect::bef_effect_get_face_detect_result_local(effect_handler_,
                                                        &face_info_);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("bef_effect_get_face_detect_result_local failed") << ret;
    return false;
  }

  res.face_count = face_info_.face_count;
  for (int i = 0; i < face_info_.face_count; ++i) {
    res.face[i].id = face_info_.base_infos[i].ID;
    res.face[i].action = face_info_.base_infos[i].action;
    res.face[i].pitch = face_info_.base_infos[i].pitch;
    memcpy(res.face[i].points, face_info_.base_infos[i].points_array,
           sizeof(float) * 106 * 2);
    memcpy(&(res.face[i].rect), &face_info_.base_infos[i].rect,
           sizeof(float) * 4);
    res.face[i].roll = face_info_.base_infos[i].roll;
    res.face[i].score = face_info_.base_infos[i].score;
    res.face[i].yaw = face_info_.base_infos[i].yaw;
  }

  return true;
}

bool EffectWrapper::GetSkeletonDetectResult(SkeletonInfo &res) {
  if (!effect_handler_) {
    KRYPTON_LOGE("effect wrapper not ready");
    return false;
  };

  bef_skeleton_result skeleton_info_;
  int ret = effect::bef_effect_get_skeleton_detect_result_local(
      effect_handler_, &skeleton_info_);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGW("bef_effect_get_skeleton_detect_result_local failed: ") << ret;
    return false;
  }

  res.skeleton_count = skeleton_info_.body_count;
  res.orientation = BEF_CLOCKWISE_ROTATE_0;
  for (int i = 0; i < skeleton_info_.body_count; ++i) {
    res.skeleton[i].id = skeleton_info_.body[i].ID;
    res.skeleton[i].rect.left = skeleton_info_.body[i].rect.left;
    res.skeleton[i].rect.right = skeleton_info_.body[i].rect.right;
    res.skeleton[i].rect.top = skeleton_info_.body[i].rect.top;
    res.skeleton[i].rect.bottom = skeleton_info_.body[i].rect.bottom;
    for (int j = 0; j < SKELETON_KEY_POINT_NUM; j++) {
      res.skeleton[i].points[j].x = skeleton_info_.body[i].point[j].x;
      res.skeleton[i].points[j].y = skeleton_info_.body[i].point[j].y;
      res.skeleton[i].points[j].isDetect =
          skeleton_info_.body[i].point[j].is_detect;
    }
  }

  return true;
}

bool EffectWrapper::GetHandDetectResult(HandInfo &res) {
  if (!effect_handler_) {
    KRYPTON_LOGE("effect wrapper not ready");
    return false;
  };

  bef_hand_info hand_info;
  int ret = effect::bef_effect_get_hand_detect_result_local(effect_handler_,
                                                            &hand_info);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGW("bef_effect_get_hand_detect_result_local failed: ") << ret;
    return false;
  }

  res.hand_count = hand_info.hand_count;
  for (int i = 0; i < hand_info.hand_count; i++) {
    const auto &hand = hand_info.p_hands[i];
    if (hand.score == 0) {
      res.hand_count = i;
      break;
    }

    res.p_hands[i].action = hand.action;
    res.p_hands[i].seq_action = hand.seq_action;
    res.p_hands[i].id = hand.id;
    res.p_hands[i].score = hand.score;
    res.p_hands[i].rot_angle = hand.rot_angle;
    res.p_hands[i].rect = {
        hand.rect.left,
        hand.rect.top,
        hand.rect.right,
        hand.rect.bottom,
    };
    for (int j = 0; j < HandInfo::HAND_KEY_POINT_NUM; j++) {
      res.p_hands[i].key_points[j] = {
          hand.key_points[j].x,
          hand.key_points[j].y,
      };
    }
    for (int j = 0; j < HandInfo::HAND_KEY_POINT_NUM_EXTENSION; j++) {
      res.p_hands[i].key_points_extension[j] = {
          hand.key_points_extension[j].x,
          hand.key_points_extension[j].y,
      };
    }
  }

  return true;
}

EffectWrapper::EffectWrapper() {
  // Muse be early init
  pthread_mutex_init(&mutex_data_, nullptr);
  memset(&default_aux_data_, 0, sizeof(default_aux_data_));
  memset(&default_face_detect_, 0, sizeof(default_face_detect_));
}

// only in js thread
int EffectWrapper::Init(std::string model_dir, std::string device_name,
                        int width, int height, bool is_use_resource_finder,
                        uint32_t algorithm_flag) {
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif

  DCHECK(effect::EffectLoaded());

  KRYPTON_LOGV("[EffectWrapper] ") << __FUNCTION__ << "...\n";
  KRYPTON_LOGW("[EffectWrapper] EffectWrapper::init with req_flag: ")
      << algorithm_flag;
  // turn on effect log
  effect::bef_effect_add_log_to_local_func_with_key_local("krypton",
                                                          effectLogFunc);

  algorithms_ = algorithm_flag;
  KRYPTON_LOGW("[EffectWrapper] algorithm_flag = ") << algorithm_flag;
  //    bool usePlatformSDK = algorithm_flag & (1u << 31);
  force_detect_face_ = false;
  bef_effect_result_t ret = 0;

  {
    char ver[1024] = {0};
    effect::bef_effect_get_sdk_version_local(ver, 1024);
    KRYPTON_LOGW("[Effect_Wrapper] EffectSDK: I'm changed ") << ver;
  }
  KRYPTON_LOGW("[Effect_Wrapper] set face\n");

  // disable ttnet related capabilities of effect
  // If enabled, ensure that the current environment ttnet has been initialized;
  // otherwise, bef will be caused_effect_destroy block
  bool ttnet_switch = false;
  effect::bef_effect_config_ab_value_local("enable_ttnet_in_effect",
                                           &ttnet_switch, 0);
  // turn on the cohesive gyroscope capability of effect
  bool sensor_services_switch = true;
  effect::bef_effect_config_ab_value_local("enable_build_in_sensor_service",
                                           &sensor_services_switch, 0);
  // turn off effect_sensor_manager_use_package_name switch
  // (after using the effectPlatformSDK scheme, you can open）
  bool sensor_use_pkg_name = false;
  effect::bef_effect_config_ab_value_local(
      "effect_sensor_manager_use_package_name", &sensor_use_pkg_name, 0);
  ret = effect::bef_effect_create_local(&effect_handler_);
  if (effect_handler_ == 0) {
    KRYPTON_LOGE("[Effect_Wrapper] fx effect init fail\n");
    return ret;
  }

  // bef_effect_set_log_level(effect_handler_, BEF_LOG_LEVEL_NONE);
  if (algorithms_ & me::BEAUTIFY) {
    ret = effect::bef_effect_use_TT_facedetect_local(effect_handler_, true);
    if (ret != BEF_RESULT_SUC) {
      KRYPTON_LOGE("[Effect_Wrapper]use TT_face detect fail, ret = ") << ret;
    }
  }
  KRYPTON_LOGW("[Effect_Wrapper] Face setted\n");

  uint64_t required_flags = 0;
  uint64_t required_params = 0;

  // open the algorithm according to the incoming flag
  // to be added: (turn on by bits)
  if (algorithms_ & me::BEAUTIFY) {
    KRYPTON_LOGW("[Effect_Wrapper] use FACE_DETECT");
    required_flags = required_flags | BEF_REQUIREMENT_FACE_DETECT;
    required_params = required_params | REQ_PARAM_MOUTH_DUDU;
  }

  if (algorithms_ & me::SKELETON) {
    KRYPTON_LOGW("[Effect_Wrapper] use SKELETON2");
    required_flags = required_flags | BEF_REQUIREMENT_SKELETON2;
  }

  if (algorithms_ & me::PLANETRACK) {
    KRYPTON_LOGW("[Effect_Wrapper] use SLAM");
    required_flags = required_flags | BEF_REQUIREMENT_SLAM;
    // NOTICE: DO NOT USE with face detect together, face detect result may be
    // null
  }

  if (algorithms_ & me::HAND) {
    KRYPTON_LOGW("[Effect_Wrapper] use HAND");
    required_flags = required_flags | BEF_REQUIREMENT_HAND_BASE;
    required_params =
        required_params | ALGORITHM_PARAM_HAND | ALGORITHM_PARAM_HAND_KEYPOINT;
  }

  requirement_ = {required_flags, required_params};

  auto resource_finder = reinterpret_cast<bef_resource_finder>(
      effect::EffectResourceDownloader::Instance()->GetResourceFinder(
          effect_handler_));
  ret = effect::bef_effect_init_with_resource_finder_local(
      effect_handler_, width, height, resource_finder, device_name.c_str());
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx effect_manage init fail, ret = ") << ret;
    return ret;
  }

  // multiple threads read the same shared_ptr is thread safe
  auto callback =
      std::bind(&EffectWrapper::SetExternalNewAlgorithm, shared_from_this());

  std::vector<std::string> requirements;
  if (algorithms_ & me::BEAUTIFY) {
    requirements.emplace_back("facedetect");
  }
  if (algorithms_ & me::SKELETON) {
    requirements.emplace_back("skeletonDetect");
  }
  if (algorithms_ & me::PLANETRACK) {
    requirements.emplace_back("AR");
  }
  if (algorithms_ & me::HAND) {
    requirements.emplace_back("handDetect");
  }

  effect::bef_effect_set_buildChain_flag_local(effect_handler_, true);
  without_face_ = false;
  KRYPTON_LOGW("[Effect_Wrapper] allsetted\n");

  return EROK;
}

int EffectWrapper::SetExternalNewAlgorithm(
    std::shared_ptr<EffectWrapper> self) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (self->effect_handler_ == 0) {
    return -1;
  }
  auto ret = effect::bef_effect_set_external_new_algorithm_local(
      self->effect_handler_, self->requirement_);
  KRYPTON_LOGW("bef_effect_set_external_new_algorithm: ret: ")
      << ret << ", alg: " << self->requirement_.algorithmParam
      << ", req: " << self->requirement_.algorithmReq;
  return ret;
}

int EffectWrapper::SetMaxMemcache(unsigned int max_mem_cache) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  bef_effect_result_t ret =
      effect::bef_effect_set_max_memcache_local(effect_handler_, max_mem_cache);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_effect fail, ret = ") << ret;
  }
  return ret;
}

int EffectWrapper::ForceDetectFace(bool is_force) {
  force_detect_face_ = is_force;
  return EROK;
}

int EffectWrapper::SwitchResource(std::string &res_name, bool without_face) {
  KRYPTON_LOGW("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  // Waiting 100ms and return if lock failed.
  //    int locked = pthread_mutex_lock_timeout(&mutex_data_, 100);
  pthread_mutex_lock(&mutex_data_);
  KRYPTON_LOGW("[Effect_Wrapper] After mutexlock");
  without_face_ = without_face;
  bef_effect_result_t ret =
      effect::bef_effect_set_effect_local(effect_handler_, res_name.c_str());
  KRYPTON_LOGW("[Effect_Wrapper] After bef_effect_set_effect");
  pthread_mutex_unlock(&mutex_data_);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx switch_resource fail, ret = ") << ret;
  }
  KRYPTON_LOGW("[Effect_Wrapper] Finish Switch Resource");
  return ret;
}

int EffectWrapper::SetFilter(std::string &filter_path, float intensity) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }
  pthread_mutex_lock(&mutex_data_);
  bef_effect_result_t ret = effect::bef_effect_set_color_filter_v2_local(
      effect_handler_, filter_path.c_str());
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_filter fail, ret = ") << ret;
  }
  ret +=
      effect::bef_effect_update_color_filter_local(effect_handler_, intensity);
  ret += effect::bef_effect_set_intensity_local(
      effect_handler_, BEF_INTENSITY_TYPE_GLOBAL_FILTER_V2, intensity);
  pthread_mutex_unlock(&mutex_data_);

  return ret;
}

int EffectWrapper::SwitchFilter(std::string &left_filter_path,
                                std::string &right_filter_path,
                                float position) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }
  pthread_mutex_lock(&mutex_data_);

  bef_effect_result_t ret = effect::bef_effect_switch_color_filter_v2_local(
      effect_handler_, left_filter_path.c_str(), right_filter_path.c_str(),
      position);
  pthread_mutex_unlock(&mutex_data_);

  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx switch_filter fail, ret = ") << ret;
  }
  return ret;
}

int EffectWrapper::SetReshape(const char *reshape_name, float eye_intensity,
                              float cheek_intensity) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  if (eye_intensity > 1.0) {
    eye_intensity = 1.0;
  }

  if (cheek_intensity > 1.0) {
    cheek_intensity = 1.0;
  }
  pthread_mutex_lock(&mutex_data_);

  bef_effect_result_t ret =
      effect::bef_effect_set_reshape_face_local(effect_handler_, reshape_name);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_reshape fail, ret = ") << ret;
  }
  ret += effect::bef_effect_update_reshape_face_intensity_local(
      effect_handler_, eye_intensity, cheek_intensity);
  pthread_mutex_unlock(&mutex_data_);

  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_reshape_intensity fail, ret = ")
        << ret;
    return ret;
  }
  return ret;
}

EffectMessageChannel *EffectWrapper::MessageChannel() {
  if (!message_channel_) {
    message_channel_ = std::unique_ptr<EffectMessageChannel>(
        std::move(EffectMessageChannel::CreateInstance()));
  }
  return message_channel_.get();
}

int EffectWrapper::DownloadSticker(const char *sticker_id,
                                   StickerDownloadCallbackType callback) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "..." << sticker_id;

  auto cb_ptr =
      std::make_unique<StickerDownloadCallbackType>(std::move(callback));
  effect::EffectResourceDownloader::Instance()->DownloadSticker(
      sticker_id, std::move(cb_ptr));

  return EROK;
}

int EffectWrapper::RemoveSticker() {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif

  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  bef_effect_result_t ret = effect::bef_effect_set_sticker_local(
      effect_handler_, 0, "", 0, false, false);

  MessageChannel()->RemoveEventCallback();

  return ret;
}

int EffectWrapper::SetSticker(const char *sticker_path,
                              EffectMessageCallbackType effect_callback) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "..." << sticker_path;
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif

  auto ret = RemoveSticker();
  if (ret != BEF_RESULT_SUC) {
    return ret;
  }
  ret = effect::bef_effect_set_sticker_local(effect_handler_, 0, sticker_path,
                                             0, false, false);
  sticker_msg_callback_ =
      std::make_unique<EffectMessageCallbackType>(std::move(effect_callback));

  MessageChannel()->AddEventCallback(sticker_msg_callback_.get());

  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx setSticker fail, ret = ") << ret;
  }
  return ret;
}

int EffectWrapper::OnPause() {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  pthread_mutex_lock(&mutex_data_);

  effect::bef_effect_onPause_local(effect_handler_, BEF_PAUSE_TYPE_ALL);

  pthread_mutex_unlock(&mutex_data_);

  return EROK;
}

int EffectWrapper::OnResume() {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  pthread_mutex_lock(&mutex_data_);

  effect::bef_effect_onResume_local(effect_handler_, BEF_PAUSE_TYPE_ALL);

  pthread_mutex_unlock(&mutex_data_);

  return EROK;
}

// this can not be called in js thread
int EffectWrapper::DoProcessTexture(unsigned int textureid_src,
                                    unsigned int textureid_dst,
                                    bef_rotate_type orientation,
                                    double time_stamp, stRoiInfo *p_roi_info) {
  // KRYPTON_LOGV("") <<  __FUNCTION__ <<  "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  //    SWITCH_TO_BG_EGL_CONTEXT;
  pthread_mutex_lock(&mutex_data_);
  bef_effect_result_t ret;
  ret = effect::bef_effect_set_orientation_local(effect_handler_, orientation);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] bef_effect_set_orientation failed, ret = ")
        << ret;
  }

  bef_face_info faceDetect;
  bef_skeleton_result skeletonResult;
  skeletonResult.body_count = -1;
  faceDetect.face_count = -1;

  bef_src_texture texture = {
      .index = textureid_src, .width = image_width_, .height = image_height_};
  bef_algorithm_param param = {.timeStamp = time_stamp};
  ret = effect::bef_effect_algorithm_multi_texture_with_params_local(
      effect_handler_, &texture, 1, &param);
  if (algorithms_ & me::BEAUTIFY) {
    auto detectRet = effect::bef_effect_get_face_detect_result_local(
        effect_handler_, &faceDetect);
    if (detectRet != BEF_RESULT_SUC) {
      KRYPTON_LOGE("[Effect_Wrapper] Face Detect Failed") << detectRet;
    }
  }

  if (p_roi_info != NULL) {
    p_roi_info->centerPosX = faceDetect.base_infos[0].points_array[46].x;
    p_roi_info->centerPosY = faceDetect.base_infos[0].points_array[46].y;
    p_roi_info->roiWidth = faceDetect.base_infos[0].rect.right -
                           faceDetect.base_infos[0].rect.left;
    p_roi_info->roiHeight = faceDetect.base_infos[0].rect.bottom -
                            faceDetect.base_infos[0].rect.top;
    p_roi_info->roiYaw = faceDetect.base_infos[0].yaw;
    p_roi_info->roiPitch = faceDetect.base_infos[0].pitch;
    p_roi_info->roiRoll = faceDetect.base_infos[0].roll;
  }

  int faceCount = faceDetect.face_count > 0 ? faceDetect.face_count : 0;

  if (faceCount <= 0 && without_face_) {
    ret = effect::
        bef_effect_process_texture_with_detection_data_and_timestamp_local(
            effect_handler_, textureid_src, textureid_dst,
            BEF_CLOCKWISE_ROTATE_0, &default_aux_data_, time_stamp);
  } else {
    ret = effect::bef_effect_process_texture_local(
        effect_handler_, textureid_src, textureid_dst, time_stamp);
  }

  pthread_mutex_unlock(&mutex_data_);

  return ret != BEF_RESULT_SUC ? -1 : 0;
}

void EffectWrapper::GetFaceDetectResult(bef_face_info &result) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (effect_handler_) {
    int ret = effect::bef_effect_get_face_detect_result_local(effect_handler_,
                                                              &result);
    if (ret != BEF_RESULT_SUC) {
      KRYPTON_LOGW("[Effect_Wrapper] Face Detect Failed: ") << ret;
      result.face_count = 0;
    }
  } else {
    result.face_count = 0;
  }
}

void EffectWrapper::GetSkeletonDetectResult(bef_skeleton_result &result) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (effect_handler_) {
    int ret = effect::bef_effect_get_skeleton_detect_result_local(
        effect_handler_, &result);
    if (ret != BEF_RESULT_SUC) {
      KRYPTON_LOGW("[Effect_Wrapper] Skeleton Detect Failed:  ") << ret;
      result.body_count = 0;
    }
  } else {
    result.body_count = 0;
  }
}

void EffectWrapper::GetHandDetectResult(bef_hand_info &result) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (effect_handler_) {
    int ret = effect::bef_effect_get_hand_detect_result_local(effect_handler_,
                                                              &result);
    if (ret != BEF_RESULT_SUC) {
      KRYPTON_LOGW("[Effect_Wrapper] Hand Detect Failed: ") << ret;
      result.hand_count = 0;
    }
  } else {
    result.hand_count = 0;
  }
}

void EffectWrapper::GetSlamDetectResult(bef_slam_info *result) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (effect_handler_) {
    int ret = effect::bef_effect_get_general_algorithm_result_local(
        effect_handler_, (bef_base_effect_info *)result, 3, 0);

    if (ret != BEF_RESULT_SUC) {
      KRYPTON_LOGW("[Effect_Wrapper] SLAM Detect Failed: ") << ret;
      result->plane_detected = -1;
      return;
    }
  } else {
    result->plane_detected = 0;
  }
}

EffectWrapper::~EffectWrapper() {
  KRYPTON_LOGW("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
  effect::bef_effect_remove_log_to_local_func_with_key_local("Krypton");
  EffectResourceDownloader::Instance()->OnEffectHandlerRelease(effect_handler_);

  // Close sticker. If it's a game, this will cause the audio players to be
  // destroyed
  std::string resource;
  RemoveSticker();
  SwitchResource(resource, without_face_);

#if !TARGET_IPHONE_SIMULATOR
  if (0 != effect_handler_) {
    effect::bef_effect_destroy_local(effect_handler_);
    KRYPTON_LOGW("[Effect_Wrapper] After bef_effect_destroy");
    effect_handler_ = 0;
  }
#endif
  pthread_mutex_destroy(&mutex_data_);

  KRYPTON_LOGW("[Effect_Wrapper] Finish ~EffectWrapper");
}

int EffectWrapper::SetDeviceRotation(float *quart) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  bef_effect_result_t ret =
      effect::bef_effect_set_device_rotation_local(effect_handler_, quart);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_device_rotation fail, ret = ") << ret;
  }

  return ret;
}

int EffectWrapper::SetWidthHeight(int width, int height) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  image_width_ = width;
  image_height_ = height;

  bef_effect_result_t ret =
      effect::bef_effect_set_width_height_local(effect_handler_, width, height);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_width_height fail, ret = ") << ret;
  }
  return ret;
}

int EffectWrapper::setBeauty(const char *res_path, float smooth_intensity,
                             float white_intensity, float sharp_intensity) {
  KRYPTON_LOGV("[Effect_Wrapper]) ")
      << __FUNCTION__ << " " << __LINE__ << " res_path: " << res_path
      << " smooth_intensity: " << smooth_intensity
      << " white_intensity: " << white_intensity
      << " sharp_intensity: " << sharp_intensity << "/n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  bef_effect_result_t ret =
      effect::bef_effect_set_beauty_local(effect_handler_, res_path);

  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] fx set_beauty fail, ret = ") << ret;
  }
  // ret = bef_effect_update_beauty(effect_handler_, fSmoothIntensity,
  // fWhiteIntensity);
  ret += effect::bef_effect_set_intensity_local(
      effect_handler_, BEF_INTENSITY_TYPE_BEAUTY_SMOOTH, smooth_intensity);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE(
        "[Effect_Wrapper] bef_effect_set_intensity SMOOTH fail, ret = ")
        << ret;
  }
  // compatible for changes in macro definition of EffectSDK
#ifdef BEF_INTENSITY_TYPE_BEAUTY_BRIGHTEN
  ret += effect::bef_effect_set_intensity_local(
      effect_handler_, BEF_INTENSITY_TYPE_BEAUTY_BRIGHTEN, white_intensity);
#else
  ret += bef_effect_set_intensity(
      effect_handler_, BEF_INTENSITY_TYPE_BEAUTY_WHITEN, white_intensity);
#endif

  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE(
        "[Effect_Wrapper] bef_effect_set_intensity WHITEN fail, ret = ")
        << ret;
  }
  ret += effect::bef_effect_set_intensity_local(
      effect_handler_, BEF_INTENSITY_TYPE_BEAUTY_SHARP, sharp_intensity);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] bef_effect_set_intensity SHARP fail, ret = ")
        << ret;
  }

  return ret;
}

int EffectWrapper::ComposerSetMode(int mode, int order_type) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  bef_effect_result_t ret = effect::bef_effect_composer_set_mode_local(
      effect_handler_, mode, order_type);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] bef_effect_composer_set_mode fail, ret = ")
        << ret;
  }
  return ret;
}

int EffectWrapper::ComposerSetNodes(const char *node_paths[], int node_num) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  auto reshape_path =
      effect::EffectResourceDownloader::Instance()->ReshapePath();
  auto qing_yan_path =
      effect::EffectResourceDownloader::Instance()->QingYanPath();

  const char *default_node_paths[] = {reshape_path, qing_yan_path};
  if (!node_paths) {
    // use the default thin face beauty composer
    node_paths = default_node_paths;
    node_num = 2;
  }

  bef_effect_result_t ret = effect::bef_effect_composer_set_nodes_local(
      effect_handler_, node_paths, node_num);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] composerSetNodes fail, ret = ") << ret;
  }
  return ret != BEF_RESULT_SUC ? -1 : 0;
}

int EffectWrapper::ComposerUpdateNode(const char *node_paths,
                                      const char *node_tag, float node_value) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  if (!node_paths) {
    if (!strcmp(node_tag, kEFFECT_TAG_WHITEN) ||
        !strcmp(node_tag, kEFFECT_TAG_BLUR)) {
      node_paths = effect::EffectResourceDownloader::Instance()->QingYanPath();
    }
    if (!strcmp(node_tag, kEFFECT_TAG_EYE) ||
        !strcmp(node_tag, kEFFECT_TAG_CHEEK)) {
      node_paths = effect::EffectResourceDownloader::Instance()->ReshapePath();
    }
  }

  bef_effect_result_t ret = effect::bef_effect_composer_update_node_local(
      effect_handler_, node_paths, node_tag, node_value);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] composerUpdateNode fail, ret = ") << ret;
  }
  return ret != BEF_RESULT_SUC ? -1 : 0;
}

int EffectWrapper::ComposerReloadNodes(const char *node_paths[], int node_num) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }

  bef_effect_result_t ret = effect::bef_effect_composer_reload_nodes_local(
      effect_handler_, node_paths, node_num);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE(
        "[Effect_Wrapper] bef_effect_composer_reload_nodes fail, ret = ")
        << ret;
  }
  return ret;
}

int EffectWrapper::ComposerAppendNodes(const char **nodes, int node_num) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }
  if (nodes == nullptr || node_num <= 0) {
    return ERINVALID_PARAM;
  }

  bef_effect_result_t ret = effect::bef_effect_composer_append_nodes_local(
      effect_handler_, nodes, node_num);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] composerAppendNodes fail, ret = ") << ret;
  }
  return ret;
}

int EffectWrapper::ComposerRemoveNodes(const char **node_paths, int node_num) {
  KRYPTON_LOGV("[Effect_Wrapper] ") << __FUNCTION__ << "...\n";
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }
  if (node_paths == nullptr || node_num <= 0) {
    return ERINVALID_PARAM;
  }

  bef_effect_result_t ret = effect::bef_effect_composer_remove_nodes_local(
      effect_handler_, node_paths, node_num);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] composerRemoveNodes fail, ret = ") << ret;
  }
  return ret;
}

// TODO: touch not yet adapted
void EffectWrapper::ProcessTouchEvent(float x, float y) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_touchEvent_local(effect_handler_, x, y);
  }
}

void EffectWrapper::ProcessPanEvent(float x, float y, float dx, float dy,
                                    float factor) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_pan_event_local(effect_handler_, x, y, dx, dy,
                                               factor);
  }
}

void EffectWrapper::ProcessLongPressEvent(float x, float y) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_long_press_event_local(effect_handler_, x, y);
  }
}

void EffectWrapper::ProcessDoubleClickEvent(float x, float y) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_double_click_event_local(effect_handler_, x, y);
  }
}

void EffectWrapper::ProcessTouchDownEvent(float x, float y, int type) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_touch_down_event_local(effect_handler_, x, y,
                                                      (bef_gesture_type)type);
  }
}

void EffectWrapper::ProcessTouchUpEvent(float x, float y, int type) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_touch_up_event_local(effect_handler_, x, y,
                                                    (bef_gesture_type)type);
  }
}

void EffectWrapper::ProcessScaleEvent(float scale, float factor) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_scaleEvent_local(effect_handler_, scale, factor);
  }
}

void EffectWrapper::ProcessRotationEvent(float rotation, float factor) {
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  if (0 != effect_handler_) {
    effect::bef_effect_process_rotationEvent_local(effect_handler_, rotation,
                                                   factor);
  }
}

int EffectWrapper::SetCameraDevicePosition(bef_camera_position position) {
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }
  KRYPTON_LOGV("[Effect_Wrapper] ")
      << __FUNCTION__ << __LINE__ << " camera position: " << position;
  bef_effect_result_t ret = effect::bef_effect_set_camera_device_position_local(
      effect_handler_, position);
  if (ret != BEF_RESULT_SUC) {
    KRYPTON_LOGE("[Effect_Wrapper] SetCameraDevicePosition fail, ret = ")
        << ret;
    return ret;
  }
  return 0;
}

int EffectWrapper::SendMessage(unsigned int msg_type, long arg1, long arg2,
                               std::string arg3) {
#if TARGET_IPHONE_SIMULATOR
  return EROK;
#endif
  if (0 == effect_handler_) {
    return ERINVALID_HANDLER;
  }
  KRYPTON_LOGV("[Effect_Wrapper] ")
      << __FUNCTION__ << " send game notify: msgType: " << msg_type
      << " , arg1: " << arg1 << " , arg2:" << arg2 << ", arg3:" << arg3;

  effect::bef_effect_send_msg_local(effect_handler_, msg_type, arg1, arg2,
                                    arg3.c_str());
  return 0;
}

void EffectWrapper::SetMockFace(bool i) { without_face_ = i; }
}  // namespace effect
}  // namespace canvas
}  // namespace lynx
