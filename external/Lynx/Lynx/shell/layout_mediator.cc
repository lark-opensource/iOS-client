// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/layout_mediator.h"

#include <utility>

#include "base/trace_event/trace_event.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/element.h"
#include "third_party/fml/make_copyable.h"
#if ENABLE_AIR
#include "tasm/air/air_element/air_element.h"
#endif

namespace lynx {
namespace shell {
#pragma mark LayoutMediator
LayoutMediator::LayoutMediator(
    const std::shared_ptr<TASMOperationQueue> &operation_queue)
    : operation_queue_(operation_queue), air_node_manager_{nullptr} {}

void LayoutMediator::OnLayoutUpdate(
    int tag, float x, float y, float width, float height,
    const std::array<float, 4> &paddings, const std::array<float, 4> &margins,
    const std::array<float, 4> &borders,
    const std::array<float, 4> *sticky_positions, float max_height) {
  std::array<float, 4> sticky_positions_clone;
  bool has_sticky = false;
  if (sticky_positions) {
    sticky_positions_clone = *sticky_positions;
    has_sticky = true;
  }

  // If node map is empty, no need to EnqueueOperation.
  // IsActive means if there is any node in node_manager(if node_manager is
  // empty means the process of loadTemplate doesn't create any node, maybe some
  // error occurs or it's in air mode, so the next step is checking if
  // air_node_manager works normally)
  // TODO(renpengcheng): when air_element was deleted, check the rationality of
  // this logic
  if (node_manager_ != nullptr && node_manager_->IsActive()) {
    operation_queue_->EnqueueOperation(
        [node_manager = node_manager_, tag, x, y, width, height, paddings,
         margins, borders, sticky_positions_clone, has_sticky, max_height]() {
          auto *node = node_manager->Get(tag);
          if (node != nullptr) {
            if (has_sticky) {
              node->UpdateLayout(x, y, width, height, paddings, margins,
                                 borders, &sticky_positions_clone, max_height);
            } else {
              node->UpdateLayout(x, y, width, height, paddings, margins,
                                 borders, nullptr, max_height);
            }
          }
        });
  }
#if ENABLE_AIR
  else if (air_node_manager_ != nullptr) {
    operation_queue_->EnqueueOperation(
        [tag, x, y, width, height, paddings, margins, borders, max_height,
         air_node_manager = air_node_manager_]() {
          std::shared_ptr<tasm::AirElement> node = air_node_manager->Get(tag);
          if (node) {
            node.get()->UpdateLayout(x, y, width, height, paddings, margins,
                                     borders, nullptr, max_height);
          }
        });
  }
#endif
}

void LayoutMediator::OnAnimatedNodeReady(int tag) {
  // If node map is empty, no need to EnqueueOperation.
  // IsActive means if there is any node in node_manager(if node_manager is
  // empty means the process of loadTemplate doesn't create any node, maybe some
  // error occurs or it's in air mode, so the next step is checking if
  // air_node_manager works normally)
  // TODO(renpengcheng): when air_element was deleted, check the rationality of
  // this logic
  if (node_manager_ != nullptr && node_manager_->IsActive()) {
    operation_queue_->EnqueueOperation([node_manager = node_manager_, tag]() {
      if (node_manager != nullptr) {
        auto *node = node_manager->Get(tag);
        if (node != nullptr) {
          node->OnAnimatedNodeReady();
        }
      }
    });
  }
#if ENABLE_AIR
  else if (air_node_manager_ != nullptr) {
    operation_queue_->EnqueueOperation(
        [node_manager = air_node_manager_, tag]() {
          if (node_manager != nullptr) {
            auto node = node_manager->Get(tag);
            if (node != nullptr) {
              node->OnAnimatedNodeReady();
            }
          }
        });
  }
#endif
}

void LayoutMediator::OnNodeLayoutAfter(int32_t id) {
  operation_queue_->EnqueueOperation([catalyzer = catalyzer_, id]() {
    if (catalyzer != nullptr) {
      catalyzer->painting_context()->OnCollectExtraUpdates(id);
    }
  });
}

void LayoutMediator::OnLayoutAfter(
    const tasm::PipelineOptions &options,
    std::unique_ptr<tasm::PlatformExtraBundleHolder> holder, bool has_layout) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LayoutMediator.OnLayoutAfter");
  bool is_first_layout = false;
  if (!has_first_layout_ && has_layout) {
    has_first_layout_ = true;
    is_first_layout = true;
  }

  if (!engine_actor_->CanRunNow()) {
    operation_queue_->AppendPendingTask();

    // FIXME(heshan):when renderTemplate has no patch, is_first_screen
    // will be false forever.
    // need to mark the flag as true in ElementManager::Delegate.
    if (is_first_layout) {
      operation_queue_->has_first_screen_ = true;
      operation_queue_->first_screen_cv_.notify_one();
    }
  }

  engine_actor_->Act([queue = operation_queue_.get(), catalyzer = catalyzer_,
                      options = options, h = std::move(holder), has_layout,
                      is_first_layout,
                      facade_actor = facade_actor_](auto &engine) mutable {
    options.has_layout = has_layout;
    if (catalyzer != nullptr && options.has_patched &&
        (options.is_first_screen || !options.timing_flag.empty())) {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "PaintingContext.UpdateOptionsForTiming",
                  [&options](lynx::perfetto::EventContext ctx) {
                    options.UpdateTraceDebugInfo(ctx.event());
                  });
      catalyzer->painting_context()->UpdateOptionsForTiming(options);
    }
    HandlePendingLayoutTask(queue, catalyzer, options);

    if (options.has_layout) {
      // TODO(heshan): now trigger onFirstScreen when first layout,
      // but it is inconsistent with options.is_first_screen.
      facade_actor->Act([is_first_screen = is_first_layout](auto &facade) {
        facade->OnPageChanged(is_first_screen);
      });
    }
  });

  if (is_first_layout) {
    runtime_actor_->ActAsync(
        [](auto &runtime) { runtime->OnAppFirstScreen(); });
  }
}

void LayoutMediator::PostPlatformExtraBundle(
    int32_t id, std::unique_ptr<tasm::PlatformExtraBundle> bundle) {
  operation_queue_->EnqueueOperation(fml::MakeCopyable(
      [catalyzer = catalyzer_, id, platform_bundle = std::move(bundle)]() {
        if (catalyzer != nullptr) {
          catalyzer->painting_context()->UpdatePlatformExtraBundle(
              id, platform_bundle.get());
        }
      }));
}

// TODO(heshan):remove related invocation
void LayoutMediator::OnLayoutFinish(base::MoveOnlyClosure<void> callback) {}

void LayoutMediator::OnCalculatedViewportChanged(
    const tasm::CalculatedViewport &viewport, int tag) {
  // Send onWindowResize to front-end
  auto arguments = lepus::CArray::Create();
  auto params = lepus::CArray::Create();
  params->push_back(lepus::Value(viewport.width / tasm::Config::Density()));
  params->push_back(lepus::Value(viewport.height / tasm::Config::Density()));
  // name
  arguments->push_back(
      lepus_value(lepus::StringImpl::Create("onWindowResize")));
  // params
  arguments->push_back(lepus_value(params));

  runtime_actor_->ActAsync([arguments = lepus_value(arguments)](auto &runtime) {
    runtime->CallJSFunction("GlobalEventEmitter", "emit", arguments);
  });

  // trigger page onResize
  engine_actor_->Act([arguments = lepus_value(arguments), tag](auto &engine) {
    engine->SendCustomEvent("resize", tag, arguments, "params");
  });
}

void LayoutMediator::SetTiming(tasm::Timing timing) {
  facade_actor_->Act([timing = std::move(timing)](auto &facade_actor) mutable {
    facade_actor->SetTiming(std::move(timing));
  });
}

void LayoutMediator::Report(
    std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  facade_actor_->ActAsync(
      [stack = std::move(stack)](auto &facade_actor) mutable {
        facade_actor->Report(std::move(stack));
      });
}

// @note: run on tasm thread
void LayoutMediator::HandlePendingLayoutTask(TASMOperationQueue *queue,
                                             tasm::Catalyzer *catalyzer,
                                             tasm::PipelineOptions options) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LayoutMediator.HandlePendingLayoutTask");
  if (catalyzer == nullptr) {
    return;
  }

  if (queue->Flush()) {
    catalyzer->UpdateLayoutRecursively();
    catalyzer->painting_context()->UpdateLayoutPatching();
    catalyzer->painting_context()->OnFirstScreen();
  } else {
    // if Flush return false, means layout has no change.
    catalyzer->UpdateLayoutRecursivelyWithoutChange();
  }

  catalyzer->painting_context()->UpdateNodeReadyPatching();

  // ensure FinishLayoutOperation in the end before Flush
  catalyzer->painting_context()->FinishLayoutOperation(options);
  catalyzer->painting_context()->Flush();
}

// @note: run on tasm thread
// Should be work on the thread that tasm work on. And must be called after
// notifying safepoint.
void LayoutMediator::HandleLayoutVoluntarily(TASMOperationQueue *queue,
                                             tasm::Catalyzer *catalyzer) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LayoutMediator.HandleLayoutVoluntarily",
              "has_first_screen_", queue->has_first_screen_.load());
  // when part on layout, usually, layout is faster than create ui.
  // even if layout slower, at most a few ms.
  // for first screen, we need ensure sync fetch layout result.
  // so just set a time out for 50ms avoid anr if some error occurred.
  // for other case, like update data, just try fetch layout result.
  using namespace std::chrono_literals;  // NOLINT
  static constexpr auto kFirstScreenWaitTimeout = 50ms;
  tasm::PipelineOptions options;

  if (!queue->has_first_screen_) {
    std::mutex first_screen_cv_mutex;
    std::unique_lock<std::mutex> local_lock(first_screen_cv_mutex);
    if (!queue->first_screen_cv_.wait_for(
            local_lock, kFirstScreenWaitTimeout,
            [queue] { return queue->has_first_screen_.load(); })) {
      LOGE("HandleLayoutVoluntarily wait layout finish failed.");
    }
  }

  HandlePendingLayoutTask(queue, catalyzer, std::move(options));
}

void LayoutMediator::OnFirstMeaningfulLayout() {
  engine_actor_->Act([catalyzer = catalyzer_](auto &engine) {
    if (catalyzer != nullptr) {
      catalyzer->painting_context()->OnFirstMeaningfulLayout();
    }
  });
}

}  // namespace shell
}  // namespace lynx
