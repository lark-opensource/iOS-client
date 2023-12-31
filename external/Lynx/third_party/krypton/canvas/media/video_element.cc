// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/media/video_element.h"

#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/canvas_app.h"
#include "canvas/canvas_element.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/media/video_context.h"
#include "canvas/platform/video_player_context.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "jsbridge/napi/callback_helper.h"

namespace lynx {
namespace canvas {

using piper::CallbackHelper;

namespace {
std::string GenerateUniqueId() {
  static uint32_t s_unique_id = 0;
  return std::to_string(++s_unique_id);
}
constexpr char collector_name[] = "kryptonVideoCollector";
}  // namespace

VideoElement::VideoElement() : id_(GenerateUniqueId()) {
  KRYPTON_CONSTRUCTOR_LOG(VideoElement);
  instance_guard_ = InstanceGuard<VideoElement>::CreateSharedGuard(this);
}

VideoElement::~VideoElement() {
  if (video_context_) {
    video_context_->RegisterStateListener(nullptr);
  }
  KRYPTON_DESTRUCTOR_LOG(VideoElement);
}

void VideoElement::SetSrc(const std::string& src) {
  KRYPTON_LOGI("VideoElement setSrc ") << this << " with " << src;
  src_ = std::move(src);

  if (!video_context_ || type_ != VideoPlayer) {
    type_ = VideoPlayer;
    video_context_ =
        VideoPlayerContext::CreatePlayer(canvas_app_, player_load_options_);
    KRYPTON_LOGI("VideoElement ")
        << this << (" VideoContext ") << video_context_.get();
    auto player = static_cast<VideoPlayerContext*>(video_context_.get());
    player->SetMuted(muted_);
    player->SetLoop(loop_);
    player->SetVolume(volume_);
    player->SetAutoplay(autoplay_);
    RegisterStateListener();
  }
  HoldObject();
  auto url = canvas_app_->resource_loader()->RedirectUrl(src_);
  static_cast<VideoPlayerContext*>(video_context_.get())->Load(url);
  state_ = kVideoStateLoading;
}

std::string VideoElement::GetSrc() const { return src_; }

void VideoElement::SetSrcObject(MediaStream* src_object) {
  KRYPTON_LOGI("VideoElement setSrcObj ") << this << " with " << src_object;

  if (!src_object || !src_object->GetVideoContext()) {
    KRYPTON_LOGI("VideoElement setSrcObject with wrong srcObject");
    Dispose();
    return;
  }

  if (src_object->GetType() != MediaStream::Type::Camera) {
    KRYPTON_LOGI("VideoElement setSrcObject with wrong type");
    Dispose();
    return;
  }

  type_ = Camera;
  src_object_ = src_object;
  src_object_ref_ = src_object->ObtainStrongRef();
  video_context_ = src_object->GetVideoContext();
  can_detect_ = video_context_->CanDetect();
  RegisterStateListener();
}

MediaStream* VideoElement::GetSrcObject() { return src_object_; }

void VideoElement::RegisterStateListener() {
  if (!video_context_) {
    return;
  }

  auto weak_guard = std::weak_ptr<InstanceGuard<VideoElement>>(instance_guard_);
  video_context_->RegisterStateListener(
      [weak_guard](VideoContext::State state) {
        auto shared_guard = weak_guard.lock();
        if (!shared_guard) {
          return;
        }
        shared_guard->Get()->NotifyState(state);
      });
}

void VideoElement::NotifyState(VideoContext::State state) {
  auto weak_guard = std::weak_ptr<InstanceGuard<VideoElement>>(instance_guard_);
  canvas_app_->runtime_actor()->Act([state, weak_guard](auto& impl) {
    auto shared_guard = weak_guard.lock();
    if (!shared_guard || shared_guard->Get()->type_ == NotReady) {
      KRYPTON_LOGW(
          "VideoElement platform notify state and video context already "
          "disposed");
      return;
    }

    const char* func_name = nullptr;
    const char* event_name = nullptr;
    switch (state) {
      case VideoContext::State::kCanPlay: {
        func_name = "oncanplay";
        event_name = "canplay";
        if (shared_guard->Get()->state_ != kVideoStatePlaying) {
          shared_guard->Get()->state_ = kVideoStateLoaded;
        }
        shared_guard->Get()->ready_state_ = HAVE_ENOUGH_DATA;
        break;
      }
        //      case VideoContext::State::kStartPlay:
        //        shared_guard->Get()->state_ = kVideoStatePlaying;
        //        return;
        //      case VideoContext::State::kPaused:
        //        shared_guard->Get()->state_ = kVideoStatePaused;
        //        return;
      case VideoContext::State::kCanDraw:
        func_name = "oncandraw";
        event_name = "candraw";
        break;
      case VideoContext::State::kSeekEnd:
        func_name = "onseekend";
        event_name = "seekend";
        break;
      case VideoContext::State::kEnd:
        func_name = "onend";
        event_name = "end";
        shared_guard->Get()->state_ = kVideoStateLoaded;
        break;
      case VideoContext::State::kError:
        func_name = "onerror";
        event_name = "error";
        shared_guard->Get()->state_ = kVideoStateError;
        break;
      default:
        return;
    }

    shared_guard->Get()->InvokeStateCallback(func_name, event_name);
  });
}

void VideoElement::InvokeStateCallback(const char* func_name,
                                       const char* event_name) {
  KRYPTON_LOGI("VideoElement ") << this << " notify status: " << event_name;
  Napi::HandleScope hscope(Env());
  Napi::ContextScope scope(Env());
  // return if VideoElement is released by GC
  if (JsObject().IsEmpty()) {
    return;
  }
  TriggerEventListeners(event_name, Env().Undefined());

  if (strcmp(event_name, "canplay") == 0 || strcmp(event_name, "error") == 0) {
    ReleaseObject();
  }
}

void VideoElement::SetCurrentTime(double currentTime) {
  if (type_ != VideoPlayer || !video_context_) {
    return;
  }

  static_cast<VideoPlayerContext*>(video_context_.get())
      ->SetCurrentTime(currentTime);
}

double VideoElement::GetCurrentTime() {
  if (type_ != VideoPlayer || !video_context_) {
    return 0;
  }

  return static_cast<VideoPlayerContext*>(video_context_.get())
      ->GetCurrentTime();
  ;
}

void VideoElement::SetMuted(bool muted) {
  if (type_ == NotReady) {
    muted_ = muted;
    return;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return;
  }

  static_cast<VideoPlayerContext*>(video_context_.get())->SetMuted(muted);
}

bool VideoElement::GetMuted() {
  if (type_ == NotReady) {
    return muted_;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return false;
  }

  return static_cast<VideoPlayerContext*>(video_context_.get())->GetMuted();
  ;
}

void VideoElement::SetVolume(double volume) {
  if (type_ == NotReady) {
    volume_ = volume;
    return;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return;
  }

  static_cast<VideoPlayerContext*>(video_context_.get())->SetVolume(volume);
}

double VideoElement::GetVolume() {
  if (type_ == NotReady) {
    return volume_;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return 0;
  }

  return static_cast<VideoPlayerContext*>(video_context_.get())->GetVolume();
  ;
}

void VideoElement::SetLoop(bool loop) {
  if (type_ == NotReady) {
    loop_ = loop;
    return;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return;
  }

  static_cast<VideoPlayerContext*>(video_context_.get())->SetLoop(loop);
}

bool VideoElement::GetLoop() {
  if (type_ == NotReady) {
    return loop_;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return false;
  }

  return static_cast<VideoPlayerContext*>(video_context_.get())->GetLoop();
  ;
}

void VideoElement::SetAutoplay(bool autoplay) {
  if (type_ == NotReady) {
    autoplay_ = autoplay;
    return;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return;
  }

  static_cast<VideoPlayerContext*>(video_context_.get())->SetAutoplay(autoplay);
}

bool VideoElement::GetAutoplay() {
  if (type_ == NotReady) {
    return autoplay_;
  }

  if (type_ != VideoPlayer || !video_context_) {
    return false;
  }

  return static_cast<VideoPlayerContext*>(video_context_.get())->GetAutoplay();
  ;
}

double VideoElement::GetDuration() {
  if (!video_context_ || type_ != VideoPlayer) {
    return NAN;
  }
  return static_cast<VideoPlayerContext*>(video_context_.get())->GetDuration();
}

unsigned short VideoElement::GetReadyState() { return ready_state_; }

bool VideoElement::GetPaused() { return state_ != kVideoStatePlaying; }

void VideoElement::Play() {
  KRYPTON_LOGI("VideoElement ") << this << " play";
  if (video_context_) {
    video_context_->Play();
  }
  state_ = kVideoStatePlaying;
}

void VideoElement::Pause() {
  KRYPTON_LOGI("VideoElement ") << this << " pause";
  if (video_context_) {
    video_context_->Pause();
  }
  state_ = kVideoStatePaused;
}

void VideoElement::Dispose() {
  KRYPTON_LOGI("VideoElement ") << this << " dispose";
  type_ = NotReady;
  src_object_ = nullptr;

  if (!src_object_ref_.IsEmpty()) {
    src_object_ref_.Unref();
  }

  if (!video_context_) {
    return;
  }

  video_context_.reset();
  state_ = kVideoStateDisposed;
}

std::shared_ptr<shell::LynxActor<TextureSource>>
VideoElement::GetTextureSource() {
  if (!video_context_) {
    return nullptr;
  }
  return video_context_->GetNewTextureSource();
}

uint32_t VideoElement::GetWidth() {
  if (!video_context_) {
    return 0;
  }
  return video_context_->Width();
}

uint32_t VideoElement::GetHeight() {
  if (!video_context_) {
    return 0;
  }
  return video_context_->Height();
}

uint32_t VideoElement::GetVideoWidth() { return GetWidth(); }

uint32_t VideoElement::GetVideoHeight() { return GetHeight(); }

std::string VideoElement::GetState() { return state_; }

double VideoElement::GetTimestamp() {
  if (type_ != Camera || !video_context_) {
    return 0;
  }

  return video_context_->Timestamp();
  ;
}

void VideoElement::PaintTo(CanvasElement* canvas, double dx, double dy,
                           double sx, double sy) {
  PaintTo(canvas, dx, dy, sx, sy, GetWidth() - sx, GetHeight() - sy);
}

void VideoElement::PaintTo(CanvasElement* canvas, double dx, double dy,
                           double sx, double sy, double sw) {
  PaintTo(canvas, dx, dy, sx, sy, sw, GetHeight() - sy);
}

void VideoElement::PaintTo(CanvasElement* canvas, double dx, double dy,
                           double sx, double sy, double sw, double sh) {
  if (!video_context_) {
    KRYPTON_LOGE("VideoElement video context == nullptr, ignore paintTo");
    return;
  }

  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      if (!texture_source_actor_->Impl()) {
        return;
      }

      texture_source_actor_->Impl()->UpdateTextureOrFramebufferOnGPU();

      Framebuffer srcFb(texture_source_actor_->Impl()->Texture());
      if (!srcFb.InitOnGPUIfNeed()) {
        return;
      }

      ScopedGLResetRestore s(GL_FRAMEBUFFER_BINDING);
      GL::BindFramebuffer(GL_READ_FRAMEBUFFER, srcFb.Fbo());
      GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, fb_);

      GLint sx = sw_ < 0 ? sx_ - sw_ : sx_;
      GLint sy = sh_ < 0 ? sy_ - sh_ : sy_;
      GLint sw = sw_;
      GLint sh = sh_;

      GLint dx = dx_;
      GLint dy = h_ - dy_;
      GLint dw = sw_ < 0 ? -sw_ : sw_;
      GLint dh = sh_ < 0 ? sh_ : -sh_;

      // flipY
      GL::BlitFramebuffer(sx, sy, sx + sw, sy + sh, dx, dy, dx + dw, dy + dh,
                          GL_COLOR_BUFFER_BIT, GL_LINEAR);
    }

    std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_actor_;
    GLuint fb_;
    double dx_, dy_, sx_, sy_, sw_, sh_, h_;
  };
  auto cmd = canvas->ResourceProvider()->GetRecorder()->Alloc<Runnable>();
  cmd->texture_source_actor_ = video_context_->GetNewTextureSource();
  cmd->fb_ = canvas->ResourceProvider()->drawing_fbo();
  cmd->dx_ = dx;
  cmd->dy_ = dy;
  cmd->sx_ = sx;
  cmd->sy_ = sy;
  cmd->sw_ = sw;
  cmd->sh_ = sh;
  cmd->h_ = canvas->GetHeight();
  canvas->ResourceProvider()->SetNeedRedraw();
}

void VideoElement::OnWrapped() {
  canvas_app_ = CanvasModule::From(Env())->GetCanvasApp();
}

// Work Arround Fix Me
void VideoElement::HoldObject() {
  Napi::Env env = Env();
  if (!env.Global().Has(collector_name)) {
    env.Global()[collector_name] = Napi::Object::New(env);
  }
  Napi::Value collector = env.Global()[collector_name];
  Napi::Object collector_obj = collector.As<Napi::Object>();
  collector_obj[id_.c_str()] = JsObject();
}

void VideoElement::ReleaseObject() {
  Napi::Env env = Env();
  if (!env.Global().Has(collector_name)) {
    return;
  }
  Napi::Value collector = env.Global()[collector_name];
  Napi::Object collector_obj = collector.As<Napi::Object>();
  if (collector_obj.Has(id_.c_str())) {
    collector_obj.Delete(id_.c_str());
  }
}

std::unique_ptr<VideoElement> VideoElement::Create(
    std::unique_ptr<VideoLoadOptions> load_options) {
  auto video_element = new VideoElement();
  video_element->ParsePlayerLoadOptions(std::move(load_options));
  return std::unique_ptr<VideoElement>(video_element);
}

void VideoElement::ParsePlayerLoadOptions(
    std::unique_ptr<VideoLoadOptions> load_options) {
  if (load_options) {
    if (load_options->hasUseCustomPlayer()) {
      player_load_options_.use_custom_player = load_options->useCustomPlayer();
    }
  }
}

}  // namespace canvas
}  // namespace lynx
