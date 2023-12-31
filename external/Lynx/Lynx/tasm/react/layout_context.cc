// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/layout_context.h"

#include <chrono>
#include <cmath>
#include <sstream>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/no_destructor.h"
#include "base/perf_collector.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/json_parser.h"
#include "lepus/table.h"
#include "starlight/layout/box_info.h"
#include "starlight/style/default_css_style.h"
#include "starlight/types/layout_directions.h"
#include "starlight/types/nlength.h"
#include "tasm/attribute_holder.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/react/element_manager.h"
#include "third_party/fml/synchronization/waitable_event.h"

namespace lynx {
namespace tasm {

using base::PerfCollector;

LayoutContext::LayoutContext(std::unique_ptr<Delegate> delegate,
                             std::unique_ptr<PlatformImpl> platform_impl,
                             int32_t trace_id)
    : platform_impl_(std::move(platform_impl)),
      delegate_(std::move(delegate)),
      root_(nullptr),
      layout_wanted_(false),
      has_viewport_ready_(false),
      enable_layout_(false),
      has_layout_required_(false),
      viewport_(),
      trace_id_(trace_id) {}

LayoutContext::~LayoutContext() {
  if (platform_impl_ != nullptr) {
    // If some nodes are not destroyed, we should destroy them.
    for ([[maybe_unused]] auto& [id, node] :
         platform_attached_nodes_registry_) {
      destroyed_platform_nodes_.insert(id);
    }
    DestroyPlatformNodesIfNeeded();
    platform_impl_->Destroy();
  }
  SetRoot(nullptr);
}

void LayoutContext::UpdateLayoutNodeProps(
    SPLayoutNode node, const std::shared_ptr<PropBundle>& props) {
  if ((node->is_common() || node->is_list()) && !node->is_inline_view()) {
    return;
  }
  platform_impl_->UpdateLayoutNode(node->id(), props.get());
}

void LayoutContext::UpdateLayoutNodeFontSize(SPLayoutNode node,
                                             double cur_node_font_size,
                                             double root_node_font_size,
                                             double font_scale) {
  node->ConsumeFontSize(cur_node_font_size, root_node_font_size, font_scale);
}

void LayoutContext::UpdateLayoutNodeStyle(SPLayoutNode node,
                                          CSSPropertyID css_id,
                                          const tasm::CSSValue& value) {
  node->ConsumeStyle(css_id, value);
}

void LayoutContext::ResetLayoutNodeStyle(SPLayoutNode node,
                                         CSSPropertyID css_id) {
  static base::NoDestructor<CSSValue> kEmpty(CSSValue::Empty());
  node->ConsumeStyle(css_id, *kEmpty.get(), true);
}

void LayoutContext::UpdateLayoutNodeAttribute(SPLayoutNode node,
                                              starlight::LayoutAttribute key,
                                              const lepus::Value& value) {
  node->ConsumeAttribute(key, value);
}

// currently unuserd
void LayoutContext::ResetLayoutNodeAttribute(SPLayoutNode node,
                                             starlight::LayoutAttribute key) {
  static base::NoDestructor<lepus::Value> kEmpty{lepus::Value()};
  node->ConsumeAttribute(key, *kEmpty, true);
}

void LayoutContext::InsertLayoutNode(SPLayoutNode parent, SPLayoutNode child,
                                     int index) {
  parent->InsertNode(child, index);
  if (!parent->is_common() && (!child->is_common() || !parent->is_list())) {
    platform_impl_->InsertLayoutNode(parent->id(), child->id(), index);
  }
}

static void FindPlatformShadowNode(const std::shared_ptr<LayoutNode>& node,
                                   std::unordered_set<int>& list) {
  if (node->is_platformed_node_attached()) {
    list.insert(node->id());
  }
  for (auto& item : node->children()) {
    FindPlatformShadowNode(item, list);
  }
}

void LayoutContext::RemoveLayoutNode(SPLayoutNode parent, SPLayoutNode child,
                                     int index, bool destroy) {
  parent->RemoveNode(child, index);
  // Recode those platform node be deleted so that we can trigger destroy on
  // platform
  if (destroy) {
    DestroyLayoutNode(child);
  }

  if (!parent->is_common() && !parent->is_list()) {
    platform_impl_->RemoveLayoutNode(parent->id(), child->id(), index);
  }
}

void LayoutContext::RegisterPlatformAttachedLayoutNode(SPLayoutNode node) {
  if (node->is_platformed_node_attached()) {
    platform_attached_nodes_registry_.emplace(node->id(), node);
  }
}

void LayoutContext::MoveLayoutNode(SPLayoutNode parent, SPLayoutNode child,
                                   int from_index, int to_index) {
  parent->MoveNode(child, from_index, to_index);
  if (!parent->is_common()) {
    platform_impl_->MoveLayoutNode(parent->id(), child->id(), from_index,
                                   to_index);
  }
}

void LayoutContext::InsertLayoutNodeBefore(SPLayoutNode parent,
                                           SPLayoutNode child,
                                           SPLayoutNode ref_node) {
  int index = 0;
  if (ref_node == nullptr) {
    // null ref node indicates to append the child to the end
    index = static_cast<int>(parent->children().size());
  } else {
    index = GetIndexForChild(parent, ref_node);
    if (index < 0) {
      LOGE("LayoutContext::InsertLayoutNodeBefore can not find child!!");
      return;
    }
  }
  InsertLayoutNode(parent, child, index);
}

void LayoutContext::RemoveLayoutNode(SPLayoutNode parent, SPLayoutNode child) {
  int index = GetIndexForChild(parent, child);
  if (index < 0) {
    LOGE("LayoutContext::RemoveLayoutNode can not find child!!");
    return;
  }
  RemoveLayoutNode(parent, child, index, false);
}

void LayoutContext::DestroyLayoutNode(SPLayoutNode node) {
  FindPlatformShadowNode(node, destroyed_platform_nodes_);
  if (!destroyed_platform_nodes_.empty()) {
    // keep the child until platform LayoutNode destroy executed
    pending_destroyed_layout_nodes_.emplace_back(node);
  }
}

int LayoutContext::GetIndexForChild(SPLayoutNode parent, SPLayoutNode child) {
  int index = 0;
  bool found = false;
  for (const auto& node : parent->children()) {
    if (node == child) {
      found = true;
      break;
    }
    ++index;
  }
  if (found) {
    return index;
  }
  return -1;
}

void LayoutContext::DispatchLayoutUpdates(const PipelineOptions& options) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LayoutContext::DispatchLayoutUpdates");
  tasm::TimingCollector::Scope<Delegate> scope(delegate_.get(),
                                               options.timing_flag);
  enable_layout_ = true;
  DestroyPlatformNodesIfNeeded();
  if (nullptr == root_ || !root_->slnode()) {
    return;
  }
  // FIXME(zhixuan): Hack below to keep a legacy logics, refactor layout context
  // to remove it. God knows why people invented dirtied_func_ and relies on it
  // to trigger a layout tick. With dirtied_func_ removed from MarkDirty
  // function, we need to request a layout tick before layout. And to minimize
  // the impact doing so, just mock the behavior of calling dirtied_func_ and
  // Layout for layout dispatched from c++.
  RequestLayout(options);
  Layout(options);
}

void LayoutContext::DispatchLayoutHasBaseline() {
  root_->SetLayoutHasBaselineRecursively(root_);
}

void LayoutContext::SetEnableLayout() {
  enable_layout_ = true;
  DestroyPlatformNodesIfNeeded();
}

void LayoutContext::SetFontFaces(const CSSFontFaceTokenMap& fontfaces) {
  platform_impl_->SetFontFaces(fontfaces);
}

void LayoutContext::Layout(const PipelineOptions& options) {
  std::string view_port_info_str;
  {
    std::stringstream ss;
    ss << " for viewport, size: " << viewport_.width << ", " << viewport_.height
       << "; mode: " << viewport_.width_mode << ", " << viewport_.height_mode;
    view_port_info_str = ss.str();
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, LYNX_TRACE_EVENT_LAYOUT,
              [&options](lynx::perfetto::EventContext ctx) {
                options.UpdateTraceDebugInfo(ctx.event());
              });
  if (root_ == nullptr || root_->slnode() == nullptr ||
      !root_->slnode()->IsDirty()) {
    if (root_ == nullptr || root_->slnode() == nullptr) {
      LOGW(
          "[Layout] Element or LayoutObject is not initialized "
          "when Layout is called"
          << view_port_info_str);
    } else {
      LOGI("[Layout] Root is clean when layout is called"
           << view_port_info_str);
      // fix layout timing when update data has patched and root no layout.
      if (options.has_patched) {
        if (options.is_first_screen) {
          tasm::TimingCollector::Instance()->Mark(
              tasm::TimingKey::SETUP_LAYOUT_START);
          tasm::TimingCollector::Instance()->Mark(
              tasm::TimingKey::SETUP_LAYOUT_END);
        } else if (!options.timing_flag.empty()) {
          tasm::TimingCollector::Instance()->Mark(
              tasm::TimingKey::UPDATE_LAYOUT_START);
          tasm::TimingCollector::Instance()->Mark(
              tasm::TimingKey::UPDATE_LAYOUT_END);
        }
      }
    }
    delegate_->OnLayoutAfter(options);
    return;
  }
  if (!enable_layout_ || !has_viewport_ready_) {
    layout_wanted_ = true;
    LOGI(
        "[Layout] Layout is disabled or view port isn't ready when "
        "Layout is called"
        << view_port_info_str);
    delegate_->OnLayoutAfter(options);
    return;
  };

  UNUSED_LOG_VARIABLE auto time_begin = std::chrono::steady_clock::now();

  if (SetViewportSizeToRootNode()) {
    root()->MarkDirty();
  }

  PerfCollector::GetInstance().StartRecord(trace_id_,
                                           PerfCollector::Perf::LAYOUT);

  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LAYOUT_START);

  if (options.is_first_screen) {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::SETUP_LAYOUT_START);
  } else if (!options.timing_flag.empty()) {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_LAYOUT_START);
  }
  // Dispatch OnLayoutBefore
  LOGI("[Layout] Layout start" << view_port_info_str);
  DispatchLayoutBeforeRecursively(root_.get());
  // CalculateLayout
  LOGV("[Layout] Computing layout" << view_port_info_str);
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_VITALS, CALCULATE_LAYOUT);
  root_->CalculateLayout();
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_VITALS);
  LOGV("[Layout] Updating layout result" << view_port_info_str);
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, LAYOUT_RECURSIVELY);
  LayoutRecursively(root());

  TryPostLayoutMetrics(!has_first_page_layout_);

  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  LOGV("[Layout] Dispatch layout after" << view_port_info_str);

  if (options.is_first_screen) {
    tasm::TimingCollector::Instance()->Mark(tasm::TimingKey::SETUP_LAYOUT_END);
  } else if (!options.timing_flag.empty()) {
    tasm::TimingCollector::Instance()->Mark(tasm::TimingKey::UPDATE_LAYOUT_END);
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ON_LAYOUT_AFTER);

  auto root_size = root()->slnode()->GetLayoutResult().size_;
  platform_impl_->UpdateRootSize(root_size.width_, root_size.height_);
  // bundle_holder is transfer and captured by this layout finish callback
  // and it is auto released at the end of this tasm loop
  auto holder = platform_impl_->ReleasePlatformBundleHolder();
  delegate_->OnLayoutAfter(options, std::move(holder), true);

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, ON_LAYOUT_FINISH);
  // FIXME(heshan): need move to painting context
  auto weak_ref = std::weak_ptr<PlatformImpl>(platform_impl_);
  delegate_->OnLayoutFinish([weak_ref]() {
    // save root size to nodeOwner
    auto strong_ref = weak_ref.lock();
    if (strong_ref != nullptr) {
      strong_ref->OnLayoutFinish();
    }
  });

  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  has_layout_required_ = false;
  layout_wanted_ = false;

  PerfCollector::GetInstance().EndRecord(trace_id_,
                                         PerfCollector::Perf::LAYOUT);

  PerfCollector::GetInstance().RecordPerfTime(
      trace_id_, PerfCollector::PerfStamp::LAYOUT_END);

  if (!has_first_page_layout_) {
    // Set the flag first, as `OnFirstMeaningfulLayout` in Renderkit may call
    // this method recursively (in the presence of <list>) and causes
    // `OnFirstMeaningfulLayout` to be called twice.
    has_first_page_layout_ = true;

    delegate_->OnFirstMeaningfulLayout();

#if !ENABLE_RENDERKIT
    base::UIThread::GetRunner()->PostTask([trace_id = trace_id_] {
#if OS_IOS
      TRACE_EVENT_INSTANT(LYNX_TRACE_CATEGORY_VITALS, FIRST_MEANINGFUL_PAINT,
                          "color",
                          LYNX_TRACE_EVENT_VITALS_COLOR_FIRST_MEANINGFUL_PAINT);
#endif
      PerfCollector::GetInstance().EndRecord(trace_id,
                                             PerfCollector::Perf::SSR_FMP);

      PerfCollector::GetInstance().EndRecord(
          trace_id, PerfCollector::Perf::FIRST_PAGE_LAYOUT);
    });
#endif
  }

  const auto& layout_result = root()->slnode()->GetLayoutResult();
  // Notify that viewport / root size has changed
  if ((calculated_viewport_.width != layout_result.size_.width_ ||
       calculated_viewport_.height != layout_result.size_.height_)) {
    calculated_viewport_.width = layout_result.size_.width_;
    calculated_viewport_.height = layout_result.size_.height_;
    delegate_->OnCalculatedViewportChanged(calculated_viewport_, root_id());
  }
  UNUSED_LOG_VARIABLE auto time_end = std::chrono::steady_clock::now();
  LOGI("[Layout] layout finish with result size: "
       << layout_result.size_.width_ << ", " << layout_result.size_.height_
       << view_port_info_str << " Time taken: "
       << std::chrono::duration_cast<std::chrono::nanoseconds>(time_end -
                                                               time_begin)
              .count()
       << " ns");
}

void LayoutContext::DispatchLayoutBeforeRecursively(LayoutNode* node) {
  if (!node->IsDirty()) {
    return;
  }
  if (node->slnode()->GetSLMeasureFunc()) {
    platform_impl_->OnLayoutBefore(node->id());
  }
  for (auto& child : node->children()) {
    DispatchLayoutBeforeRecursively(child.get());
  }
}

void LayoutContext::UpdateLayoutInfo(LayoutNode* node) {
  // Faster than use YGTransferLayoutOutputsRecursive in YGJNI.cc by 0.5 times
  auto sl_node = node->slnode();
  if (!sl_node) return;
  const auto& layout_result = sl_node->GetLayoutResult();
  float width = layout_result.size_.width_;
  float height = layout_result.size_.height_;
  float top = layout_result.offset_.Y();
  float left = layout_result.offset_.X();
  std::array<float, 4> paddings;
  std::array<float, 4> margins;
  std::array<float, 4> borders;
  // paddings
  paddings[0] = layout_result.padding_[starlight::kLeft];
  paddings[1] = layout_result.padding_[starlight::kTop];
  paddings[2] = layout_result.padding_[starlight::kRight];
  paddings[3] = layout_result.padding_[starlight::kBottom];
  // margins
  margins[0] = layout_result.margin_[starlight::kLeft];
  margins[1] = layout_result.margin_[starlight::kTop];
  margins[2] = layout_result.margin_[starlight::kRight];
  margins[3] = layout_result.margin_[starlight::kBottom];
  // borders
  borders[0] = layout_result.border_[starlight::kLeft];
  borders[1] = layout_result.border_[starlight::kTop];
  borders[2] = layout_result.border_[starlight::kRight];
  borders[3] = layout_result.border_[starlight::kBottom];

  std::array<float, 4>* sticky_positions = nullptr;
  std::array<float, 4> sticky_pos_array;
  if (sl_node->IsSticky()) {
    sticky_pos_array[0] = layout_result.sticky_pos_[starlight::kLeft];
    sticky_pos_array[1] = layout_result.sticky_pos_[starlight::kTop];
    sticky_pos_array[2] = layout_result.sticky_pos_[starlight::kRight];
    sticky_pos_array[3] = layout_result.sticky_pos_[starlight::kBottom];
    sticky_positions = &sticky_pos_array;
  }

  delegate_->OnLayoutUpdate(
      node->id(), left, top, width, height, paddings, margins, borders,
      sticky_positions, sl_node->GetCSSStyle()->GetMaxHeight().GetRawValue());

  if (node->slnode()->GetSLMeasureFunc()) {
    // Dispatch OnLayoutAfter to those nodes that have custom measure
    platform_impl_->OnLayout(node->id(), left, top, width, height);
    delegate_->OnNodeLayoutAfter(node->id());

    // if node has custom measure function, it may by need pass some bundle to
    auto bundle = platform_impl_->GetPlatformExtraBundle(node->id());

    if (!bundle) {
      return;
    }

    delegate_->PostPlatformExtraBundle(node->id(), std::move(bundle));
  }
}

void LayoutContext::MarkNodeAnimated(SPLayoutNode node, bool animated) {
  node->MarkIsAnimated(animated);
}

void LayoutContext::OnAnimatedNodeReady(LayoutNode* node) {
  delegate_->OnAnimatedNodeReady(node->id());
}

void LayoutContext::TryPostLayoutMetrics(bool first_perf) {
  if (!base::LynxEnv::GetInstance().IsLayoutPerformanceEnabled() || !root()) {
    return;
  }
  std::queue<LayoutNode*> que;
  que.push(root());

  base::scoped_refptr<lepus::CArray> node_perfs = lepus::CArray::Create();
  while (!que.empty()) {
    LayoutNode* node = que.front();
    que.pop();

    const std::vector<starlight::LayoutPref>& layout_prefs =
        node->GetLayoutPerfList();

    for (const auto& entry : layout_prefs) {
      auto node_perf = lepus::Dictionary::Create();
      node_perf->SetValue("nodeId", lepus::Value(node->id()));
      node_perf->SetValue(
          "parentId", lepus::Value(node->parent() ? node->parent()->id() : -1));
      node_perf->SetValue("layoutBeginTime", lepus::Value(entry.start_time_));
      node_perf->SetValue("layoutEndTime", lepus::Value(entry.end_time_));
      node_perf->SetValue("layoutDuration", lepus::Value(entry.duration_time_));
      node_perf->SetValue("layoutOrder", lepus::Value(entry.perf_id_));
      node_perf->SetValue("hasLayoutCache", lepus::Value(entry.has_cache_));
      node_perf->SetValue("isFinalMeasure",
                          lepus::Value(entry.is_final_measure_));

      node_perfs->push_back(lepus::Value(node_perf));
    }

    for (const auto& child_node : node->children()) {
      que.push(child_node.get());
    }
  }

  auto perf_json = lepus::Dictionary::Create();
  perf_json->SetValue(
      "frameId",
      lepus::Value(static_cast<int64_t>(
          std::chrono::system_clock::now().time_since_epoch().count())));
  perf_json->SetValue("pipeline",
                      lepus::Value(lepus::StringImpl::Create("layout")));
  perf_json->SetValue("pageStage", lepus::Value(lepus::StringImpl::Create(
                                       first_perf ? "firstPerf" : "update")));
  perf_json->SetValue("data", lepus::Value(node_perfs));

  std::string json = lepus::lepusValueToJSONString(lepus::Value(perf_json));

  auto hierarchy_observer = hierarchy_observer_.lock();
  if (hierarchy_observer) {
    hierarchy_observer->OnLayoutPerformanceCollected(json);
  }
}

void LayoutContext::LayoutRecursively(LayoutNode* node) {
  if (!node->IsDirty()) {
    return;
  }

  if (node->slnode()) {
    if (node->slnode()->GetHasNewLayout()) {
      UpdateLayoutInfo(node);
    } else if (node->IsAnimated()) {
      LOGI("LayoutRecursively force notify node layout finish.");
      OnAnimatedNodeReady(node);
    }
  }

  // If node has measure func, we will not layout it's child
  // TODO: add hasCustomLayout flag if a node can handle layouting
  // children without layout system
  if (node->slnode() && !node->slnode()->GetSLMeasureFunc()) {
    for (auto& child : node->children()) {
      LayoutRecursively(child.get());
    }
  } else if (node->slnode() && node->slnode()->GetSLMeasureFunc()) {
    LayoutRecursivelyForInlineVIew(node);
    // make sure all inline-image object is mark updated
    // so next time when css change happend on these object
    // they can mark dirty and triger layout
    for (auto const& child : node->children()) {
      if (!child->is_virtual()) {
        child->MarkUpdated();
      }
    }
  }
  node->MarkUpdated();
}

void LayoutContext::LayoutRecursivelyForInlineVIew(LayoutNode* node) {
  for (auto& child : node->children()) {
    if (child->is_common() || child->is_inline_view()) {
      // inline view.
      LayoutRecursively(child.get());
    } else {
      // try find inline view.
      LayoutRecursivelyForInlineVIew(child.get());
    }
  }
}

void LayoutContext::DestroyPlatformNodesIfNeeded() {
  if (!destroyed_platform_nodes_.empty()) {
    std::vector<int> temp_nodes(destroyed_platform_nodes_.begin(),
                                destroyed_platform_nodes_.end());
    platform_impl_->DestroyLayoutNodes(temp_nodes);
    for (const auto& node_id : temp_nodes) {
      platform_attached_nodes_registry_.erase(node_id);
    }
    destroyed_platform_nodes_.clear();
    pending_destroyed_layout_nodes_.clear();
  }
}

void LayoutContext::SetRoot(std::shared_ptr<LayoutNode> root) {
  root_ = root;

  if (!root) return;

  // The default flex direction is column for root
  root_->slnode()->GetCSSMutableStyle()->SetFlexDirection(
      starlight::FlexDirectionType::kColumn);

  root_->slnode()->SetContext(this);
  root_->slnode()->SetSLRequestLayoutFunc([](void* context) {
    static_cast<LayoutContext*>(context)->RequestLayout();
  });

  // We should update viewport when root and layout scheduler are attached,
  // as viewport has been set before.
  if (has_viewport_ready_) {
    UpdateViewport(viewport_.width, viewport_.width_mode, viewport_.height,
                   viewport_.height_mode);
  }
}

bool LayoutContext::SetViewportSizeToRootNode() {
  if (!root() || !has_viewport_ready_) {
    return false;
  }

  bool is_dirty = false;
  switch (viewport_.width_mode) {
    case SLMeasureModeDefinite:
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetWidth(
          starlight::NLength::MakeUnitNLength(viewport_.width));
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetMaxWidth(
          starlight::DefaultCSSStyle::SL_DEFAULT_MAX_WIDTH());
      break;
    case SLMeasureModeAtMost:
      // When max width is set, the pre width mode must be clear
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetWidth(
          starlight::NLength::MakeAutoNLength());
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetMaxWidth(
          starlight::NLength::MakeUnitNLength(viewport_.width));
      break;
    case SLMeasureModeIndefinite:
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetWidth(
          starlight::NLength::MakeAutoNLength());
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetMaxWidth(
          starlight::DefaultCSSStyle::SL_DEFAULT_MAX_WIDTH());
      break;
  }

  switch (viewport_.height_mode) {
    case SLMeasureModeDefinite:
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetHeight(
          starlight::NLength::MakeUnitNLength(viewport_.height));
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetMaxHeight(
          starlight::DefaultCSSStyle::SL_DEFAULT_MAX_HEIGHT());
      break;
    case SLMeasureModeAtMost:
      // When max height is set, the pre height mode must be clear
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetHeight(
          starlight::NLength::MakeAutoNLength());
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetMaxHeight(
          starlight::NLength::MakeUnitNLength(viewport_.height));
      break;
    case SLMeasureModeIndefinite:
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetHeight(
          starlight::NLength::MakeAutoNLength());
      is_dirty |= root()->slnode()->GetCSSMutableStyle()->SetMaxHeight(
          starlight::DefaultCSSStyle::SL_DEFAULT_MAX_HEIGHT());
      break;
  }
  return is_dirty;
}

void LayoutContext::UpdateViewport(float width, int width_mode, float height,
                                   int height_mode, bool need_layout) {
  viewport_.UpdateViewport(width, width_mode, height, height_mode);
  has_viewport_ready_ = true;

  LOGI("[Layout] UpdateViewport size"
       << viewport_.width << ", " << viewport_.height
       << "; mode: " << viewport_.width_mode << ", " << viewport_.height_mode);

  if (SetViewportSizeToRootNode() || (root() && root()->slnode()->IsDirty())) {
    circular_layout_detector_.DetectCircularLayoutDependency();
    root()->slnode()->MarkDirty();
    if (need_layout) {
#if ENABLE_RENDERKIT
      layout_wanted_ = true;
#endif
      RequestLayout();
    }
  }
}

void LayoutContext::UpdateLynxEnvForLayoutThread(LynxEnvConfig env) {
  if (!root()) {
    return;
  }

  root()->slnode()->UpdateLynxEnv(env);
}

void LayoutContext::RequestLayout(const PipelineOptions& options) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LayoutContext.RequestLayout",
              [&options](lynx::perfetto::EventContext ctx) {
                options.UpdateTraceDebugInfo(ctx.event());
              });
  if (root()->slnode()->IsDirty()) {
    if (layout_wanted_) {
      Layout(options);
    } else if (!has_layout_required_) {
      has_layout_required_ = true;
      platform_impl_->ScheduleLayout([this]() { request_layout_callback_(); });
    }
  }
}

void LayoutContext::OnUpdateDataWithoutChange() {
  if (platform_impl_) {
    platform_impl_->OnUpdateDataWithoutChange();
  }
}

void LayoutContext::CircularLayoutDependencyDetector::
    DetectCircularLayoutDependency() {
  const auto now = lynx::base::CurrentTimeMilliseconds();
  if (last_viewport_update_time_ == -1) {
    continuous_viewport_update_start_time_ = last_viewport_update_time_ = now;
    return;
  }
  if (now - last_viewport_update_time_ > kContinuousViewportUpdateMaxGap) {
    continuous_viewport_update_start_time_ = now;
  }
  if (now - continuous_viewport_update_start_time_ > kTimeWindow) {
    if (!in_error_state_) {
      LynxWarning(false, LYNX_ERROR_CODE_LAYOUT,
                  "Viewport update is triggered continuously through "
                  "%lld[ms]. Check for circular layout dependencies!",
                  kTimeWindow);
      in_error_state_ = true;
    }
  } else {
    in_error_state_ = false;
  }
  last_viewport_update_time_ = now;
}

void LayoutContext::Report(
    std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  delegate_->Report(std::move(stack));
}

}  // namespace tasm
}  // namespace lynx
