// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/audio_engine.h"

#include <unistd.h>

#include "aurum/config.h"
#include "aurum/util/time.hpp"
#include "base/threading/thread_local.h"
#include "canvas/base/log.h"
#include "jsbridge/napi/callback_helper.h"

namespace lynx {
namespace canvas {
namespace au {

Sample AudioEngine::Consume(int samples) {
  if (!running_) {
    return Sample::Empty();
  }

  int cycle = ++cycle_count_;
  AudioContext &ctx = GetContext();
  ctx.consume_begin_time = au::CurrentTimeUs();

  // Release expired loaders
  if ((cycle & 127) == 0) {
    AU_LOCK(ctx.loader_lock);
    for (auto it = ctx.loaders.Begin(); it.Next();) {
      AudioLoader &loader = *it;
      loader.deref_countdown--;
      if (!loader.deref_countdown) {
        KRYPTON_LOGV("release timeout loader ") << loader.path;
        ctx.loaders.Release(it.id);
      }
    }
    AU_UNLOCK(ctx.loader_lock);
  }

  // Traverse all nodes of destination
  AudioDestinationNode &dest = ctx.Dest().As<AudioDestinationNode>();
  Sample output = dest.Process(ctx, samples, cycle);

  // Traverse active node and sample source
  MixerInfo sample_mixer_for_record;
  for (AudioNode *active = &ctx.Dest(); active; active = active->active_next) {
    AudioNode &node = *active;

    if (node->is_sample_source && node->is_aec_node) {
      AudioAECNode &aec = node.As<AudioAECNode>();
      aec.SetAecBackgroundSample(output);
    }

    Sample tmp_output = node->Process(ctx, samples, cycle);

    if (!sample_callbacks_.empty() && tmp_output.length &&
        node->is_sample_source) {
      sample_mixer_for_record.push_back(tmp_output);
    }
  }

  if (!sample_callbacks_.empty()) {
    // for recording
    Mixer mixer;
    Sample sample = mixer.Mix(std::move(sample_mixer_for_record));
    for (auto it = sample_callbacks_.begin(); it != sample_callbacks_.end();
         ++it) {
      (*it)->OnSample(sample.data, sample.length, samples);
    }
  }

  if (ctx.post_volume >= 0) {
    DoMultiply(output, ctx.post_volume);
  }
  return output;
}

void AudioNodeBase::Dispatch(NodeEvent event, const AudioContext &ctx,
                             std::string err_msg) {
  class AudioNodeDispatchTask {
   public:
    inline AudioNodeDispatchTask(const AudioContext &ctx, int node_id,
                                 NodeEvent event, std::string err_msg)
        : ctx_(ctx), node_id_(node_id), event_(event), err_msg_(err_msg) {}

    void OnDispatch() const {
      ctx_.engine->SendNodeEvent(node_id_, event_, err_msg_);
    }

    static void OnDispatch(const AudioNodeDispatchTask *ptr) {
      if (ptr) {
        ptr->OnDispatch();
        delete ptr;
      }
    }

   private:
    const AudioContext &ctx_;
    int node_id_;
    NodeEvent event_;
    std::string err_msg_;
  };
  ctx.engine->Dispatch(new AudioNodeDispatchTask(ctx, id_, event, err_msg),
                       AudioNodeDispatchTask::OnDispatch);
}

void AudioEngine::BindSampleCallbackContext(SampleCallbackContext *cb_ctx) {
  if (cb_ctx == nullptr) {
    KRYPTON_LOGE("NULL SampleCallbackContext");
    return;
  }

  // do not care old sample_callback_context
  cb_ctx->audio_impl = audio_impl_;
  sample_callback_context_ = cb_ctx;
}

void AudioEngine::SetBgmVolume(float value) { GetContext().bgm_volume = value; }

void AudioEngine::SetMicVolume(float value) { GetContext().mic_volume = value; }

void AudioEngine::SetPostVolume(float value) {
  GetContext().post_volume = value;
}

void AudioEngine::PauseCapture() {
  if (running_ && audio_capture_) {
    audio_capture_->Stop();
  }
}

void AudioEngine::ResumeCapture() {
  if (running_ && audio_capture_ && !audio_impl_->IsPaused()) {
    audio_capture_->Start();
  }
}

void AudioEngine::SendNodeEvent(int node_id, AudioNodeBase::NodeEvent event,
                                const std::string &err_msg) {
  Napi::ContextScope cscope(env_);
  Napi::HandleScope hscope(env_);
  Napi::Value dispatch_callback = exports_.Value()["dispatch_callback"];
  if (!dispatch_callback.IsFunction()) {
    KRYPTON_LOGW("SendNodeEvent ")
        << node_id << int(event) << " dispatch_callback is not function";
    return;
  }

  lynx::piper::CallbackHelper helper;
  Napi::Function dispatch_callback_function =
      dispatch_callback.As<Napi::Function>();
  if (!helper.PrepareForCall(dispatch_callback_function)) {
    KRYPTON_LOGW("SendNodeEvent ")
        << node_id << int(event) << " PrepareForCall error";
    return;
  }
  if (event == AudioNodeBase::NodeEvent::Error) {
    auto res = Napi::Object::New(env_);
    res["errMsg"] = err_msg.c_str();
    helper.Call({
        Napi::Number::New(env_, uint32_t(event)),
        Napi::Number::New(env_, node_id),
        res,
    });
  } else {
    helper.Call({
        Napi::Number::New(env_, uint32_t(event)),
        Napi::Number::New(env_, node_id),
    });
  }
}
void AudioEngine::SendDecodeResult(int execute_id, bool success, int channels,
                                   int sample_rate, int samples, float *data) {
  Napi::ContextScope cscope(env_);
  Napi::HandleScope hscope(env_);
  Napi::Value execute_callback = exports_.Value()["execute_callback"];
  if (!execute_callback.IsFunction()) {
    KRYPTON_LOGW("SendDecodeResult ")
        << execute_id << success << "  execute_callback is not function";
    return;
  }

  lynx::piper::CallbackHelper helper;
  Napi::Function execute_callback_function =
      execute_callback.As<Napi::Function>();
  if (!helper.PrepareForCall(execute_callback_function)) {
    KRYPTON_LOGW("SendDecodeResult ")
        << execute_id << success << " prepareForCall is not function";
    return;
  }

  auto res = Napi::Object::New(env_);
  res["id"] = Napi::Number::New(env_, execute_id);
  if (success) {
    auto res_data = Napi::Object::New(env_);
    res["data"] = res_data;
    res_data["sampleRate"] = Napi::Number::New(env_, sample_rate);
    res_data["channels"] = Napi::Number::New(env_, channels);
    res_data["buffer"] = Napi::ArrayBuffer::New(
        env_, data, samples * channels * sizeof(float),
        [](napi_env env, void *napi_data, void *a) { free(napi_data); },
        (void *)nullptr);
  } else {
    res["data"] = Napi::Value();
  }

  helper.Call({
      Napi::Number::New(
          env_, uint32_t(au::AudioEngine::ExecuteEvent::AudioDataDecode)),
      res,
  });
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
