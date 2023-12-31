// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_page.h"

#include <numeric>
#include <utility>

#include "base/log/logging.h"
#include "base/perf_collector.h"
#include "base/string/string_number_convert.h"
#include "base/trace_event/trace_event.h"
#include "lepus/context.h"
#include "starlight/style/computed_css_style.h"
#include "tasm/base/base_def.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/timing.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {
using base::PerfCollector;

RadonPage::RadonPage(PageProxy *proxy, int tid, CSSFragment *style_sheet,
                     std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
                     PageMould *mould, lepus::Context *context)
    : RadonComponent(proxy, tid, style_sheet, style_sheet_manager, mould,
                     context, kRadonInvalidNodeIndex, "page"),
      proxy_(proxy) {
  node_type_ = kRadonPage;
  if (!context_) {
    return;
  }
  entry_name_ = context_->name();
  UpdatePageData(kSystemInfo, GenerateSystemInfo(nullptr), true);
}

void RadonPage::DeriveFromMould(ComponentMould *data) {
  if (data == nullptr || !data->data().IsObject()) {
    return;
  }
  ForEachLepusValue(
      data->data(), [this](const lepus::Value &key, const lepus::Value &value) {
        context_->UpdateTopLevelVariable(key.String()->str(), value);
      });
}

RadonPage::~RadonPage() {
  if (page_proxy_ && page_proxy_->element_manager()) {
    page_proxy_->element_manager()->SetRoot(nullptr);
  }
}

void RadonPage::UpdateComponentData(const std::string &id,
                                    const lepus::Value &table) {
  ResetComponentDispatchOrder();
  int i_id = atoi(id.c_str());
  if (proxy_->component_map_.find(i_id) != proxy_->component_map_.end()) {
    RadonComponent *component = proxy_->component_map_[i_id];

    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "UpdateComponentData",
                [&](lynx::perfetto::EventContext ctx) {
                  std::string info = ConcatUpdateDataInfo(component, table);
                  LOGI(info);
                  auto *debug = ctx.event()->add_debug_annotations();
                  debug->set_name("Info");
                  debug->set_string_value(info);
                });
    DispatchOption dispatch_option(page_proxy_);
    dispatch_option.timing_flag_ = tasm::GetTimingFlag(table);
    component->UpdateRadonComponent(
        BaseComponent::RenderType::UpdateFromJSBySelf, lepus::Value(), table,
        dispatch_option);
    TriggerComponentLifecycleUpdate(BaseComponent::kAttached);
    PipelineOptions pipeline_options;
    pipeline_options.timing_flag = dispatch_option.timing_flag_;
    pipeline_options.has_patched = dispatch_option.has_patched_;
    if (proxy_->IsRadonDiff()) {
      page_proxy_->element_manager()->OnPatchFinishFromRadon(
          dispatch_option.has_patched_, pipeline_options);
    } else {
      /*
       * in radon mode, hsa_patched_ flag may be changed in update function
       * (tt:if and tt:for). But we can't modify has_patched_ flag in update
       * function now. Here we call OnPatchFinishInner manually to avoid some
       * bad case.
       */
      page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
    }
    TriggerComponentLifecycleUpdate(BaseComponent::kReady);
  }
}

bool RadonPage::NeedsExtraData() const {
  if (page_proxy_ == nullptr) {
    return true;
  }

  if (page_proxy_->IsServerSideRendering()) {
    // For SSR, currently we kept old behavior
    return true;
  }

  return !page_proxy_->GetEnableRemoveComponentExtraData();
}

std::unique_ptr<lepus::Value> RadonPage::GetPageData() {
  if (ShouldKeepPageData()) {
    return std::make_unique<lepus::Value>(lepus::Value::Clone(data_));
  } else {
    return context_->GetTopLevelVariable(true);
  }
}

// acquire specified value from page data.
lepus::Value RadonPage::GetPageDataByKey(const std::vector<std::string> &keys) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetPageDataByKey",
              [&keys](perfetto::EventContext ctx) {
                ctx.event()->set_name("GetPageDataByKey");
                auto *debug = ctx.event()->add_debug_annotations();
                debug->set_name("keys");
                std::string str =
                    std::accumulate(keys.begin(), keys.end(), std::string{},
                                    [](std::string &s1, const std::string &s2) {
                                      return s1.append(",").append(s2);
                                    });
                debug->set_string_value(str);
              });

  using TopLevelVariableFinder =
      base::MoveOnlyClosure<lepus::Value, const std::string &>;

  // if ShouldKeepPageData, find from data, else find from context
  auto finder =
      ShouldKeepPageData()
          ? TopLevelVariableFinder{[&data = data_](const std::string &key) {
              return data.GetProperty(key);
            }}
          : TopLevelVariableFinder{[ctx = context_](const std::string &key) {
              auto val = lepus::Value();
              ctx->GetTopLevelVariableByName(key, &val);
              return val;
            }};

  lepus::Value result = lepus::Value(lepus::Dictionary::Create());

  std::for_each(keys.cbegin(), keys.cend(),
                [&result, &finder](const std::string &key) {
                  result.Table()->SetValue(key, finder(key));
                });

  return result;
}

// comp_id == "" or "card" indicates the component to get is the card
RadonComponent *RadonPage::GetComponent(const std::string &comp_id) {
  if (comp_id.empty() || comp_id == PAGE_ID) {
    return this;
  }

  int i_id;
  if (!base::StringToInt(comp_id, &i_id, 10)) {
    return nullptr;
  }
  auto it = proxy_->component_map_.find(i_id);
  if (it == proxy_->component_map_.end()) {
    return nullptr;
  };
  return it->second;
}

void RadonPage::CreatePage() {
  if (proxy_->IsRadonDiff()) {
    /*
     * No need to call renderPage because renderPage will be called when the
     * page update for the first time Why not call here? Because some PageData
     * hasn't been set yet. The call would be a waste.
     */
    return;
  }
  PerfCollector::GetInstance().StartRecord(
      proxy_->client_->GetTraceId(), PerfCollector::Perf::DIFF_ROOT_CREATE);
  PerfCollector::GetInstance().RecordPerfTime(
      proxy_->client_->GetTraceId(), PerfCollector::PerfStamp::DIFF_ROOT_START);
  lepus::Value p1(this);
  context_->Call("$createPage0", {p1});
  PerfCollector::GetInstance().EndRecord(proxy_->client_->GetTraceId(),
                                         PerfCollector::Perf::DIFF_ROOT_CREATE);
  PerfCollector::GetInstance().RecordPerfTime(
      proxy_->client_->GetTraceId(), PerfCollector::PerfStamp::DIFF_ROOT_END);
}

bool RadonPage::UpdatePage(const lepus::Value &table,
                           const UpdatePageOption &update_page_option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_UPDATE_DATA,
              [&](lynx::perfetto::EventContext ctx) {
                std::string info = ConcatUpdateDataInfo(this, table);
                LOGI(info);
                auto *debug = ctx.event()->add_debug_annotations();
                debug->set_name("Info");
                debug->set_string_value(info);
                std::string defaultInfo = ConcatUpdateDataInfo(this, data_);
                auto *debug_default_data = ctx.event()->add_debug_annotations();
                debug_default_data->set_name("defaultData");
                debug_default_data->set_string_value(defaultInfo);
              });
  // UpdateFromJSBySelf
  if (!update_page_option.from_native &&
      !update_page_option.update_first_time) {
    SetRenderType(RenderType::UpdateFromJSBySelf);
    if (IsReact() && CheckReactShouldAbortUpdating(table)) {
      return false;
    }
  } else if (update_page_option.update_first_time) {
    // FirstRender
    SetRenderType(RenderType::FirstRender);
  } else if (update_page_option.from_native) {
    // UpdateByNative
    SetRenderType(RenderType::UpdateByNative);

    // TODO(wangqingyu): TT should also reset when support data version
    if (IsReact() && update_page_option.reload_template) {
      // For reload template, we should reset data versions
      // since js counter parts are re-created with init version
      // Otherwise, all setState will be aborted
      ResetDataVersions();
    }

    if (should_component_update_function_.IsCallable()) {
      set_pre_data(lepus::Value::ShallowCopy(data_));
      set_pre_properties(lepus::Value::ShallowCopy(properties_));
    }
  }

  bool need_update = invalidated();
  bool should_component_render = true;
  if (update_page_option.reset_page_data ||
      update_page_option.reload_template || update_page_option.reload_from_js) {
    need_update = ResetPageData();
  }
  if (update_page_option.global_props_changed ||
      update_page_option.reload_from_js) {
    // when native update global props or reload from JS, need trigger children
    // render
    need_update = true;
  }
  if (enable_check_data_when_update_page_ &&
      !update_page_option.update_first_time &&
      !update_page_option.global_props_changed &&
      !update_page_option.reload_from_js) {
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_VITALS,
                      "RadonPage::UpdatePage::CheckTableShouldUpdated");
    bool update_data_is_equal = false;
    if (ShouldKeepPageData()) {
      if (data_.IsObject()) {
        update_data_is_equal = !CheckTableShadowUpdated(data_, table);
      }
    } else {
      update_data_is_equal =
          !context_->CheckTableShadowUpdatedWithTopLevelVariable(table);
    }
    if (update_data_is_equal) {
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY_VITALS);
      PipelineOptions pipeline_options;
      pipeline_options.native_update_data_order_ =
          update_page_option.native_update_data_order_;
      page_proxy_->element_manager()->OnPatchFinishFromRadon(false,
                                                             pipeline_options);
      return need_update;
    }
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY_VITALS);
  }
  ForEachLepusValue(
      table, [this, &need_update, &should_component_render](
                 const lepus::Value &key, const lepus::Value &value) {
        if (key.String()->str() == REACT_SHOULD_COMPONENT_UPDATE_KEY) {
          should_component_render = value.Bool();
          return;
        }
        if (UpdatePageData(key.String()->str(), value)) {
          need_update = true;
        }
      });

  if (!should_component_render) {
    return need_update;
  }
  std::string timing_flag;
  ResetComponentDispatchOrder();
  bool should_component_update = PrePageRender(table);
  DispatchOption option(page_proxy_);
  this->Reset();
  if (!proxy_->IsRadonDiff()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "RadonPage::UpdatePage::Radon");
    PerfCollector::GetInstance().StartRecord(
        proxy_->client_->GetTraceId(), PerfCollector::Perf::DIFF_SAME_ROOT);

    PerfCollector::GetInstance().RecordPerfTime(
        proxy_->client_->GetTraceId(), PerfCollector::PerfStamp::START_DIFF);
    // using radon
    LOGI("RadonPage::UpdatePage in Radon");
    // no first screen, check shouldComponent update
    if (!should_component_update) {
      LOGI("should_component_update is false in RadonPage::UpdatePage.");
      return need_update;
    }

    timing_flag = tasm::GetTimingFlag(table);
    if (update_page_option.update_first_time) {
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_CREATE_VDOM_START);
    } else {
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_CREATE_VDOM_START);
    }
    lepus::Value p1(this);
    lepus::Value p2(data_);
    // Before lynx 2.1, $updatePage0 accept only the previous one params.
    std::string ss = "$updatePage0";
    context_->Call(ss, {p1, p2});
    if (update_page_option.update_first_time) {
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_CREATE_VDOM_END);
      page_proxy_->element_manager()
          ->painting_context()
          ->MarkUIOperationQueueFlushTiming(
              tasm::TimingKey::SETUP_UI_OPERATION_FLUSH_START, "");
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_DISPATCH_START);
    } else if (!timing_flag.empty()) {
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_CREATE_VDOM_END);
      page_proxy_->element_manager()
          ->painting_context()
          ->MarkUIOperationQueueFlushTiming(
              tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_START, timing_flag);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_DISPATCH_START);
    }
    // just dispatch, no need to diff when the page update for the first time
    Dispatch(option);
    if (update_page_option.update_first_time) {
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_DISPATCH_END);
    } else {
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_DISPATCH_END);
    }
    PerfCollector::GetInstance().EndRecord(proxy_->client_->GetTraceId(),
                                           PerfCollector::Perf::DIFF_SAME_ROOT);

    PerfCollector::GetInstance().RecordPerfTime(
        proxy_->client_->GetTraceId(), PerfCollector::PerfStamp::END_DIFF);
  } else {
    // using radon diff
    TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, "RadonPage::UpdatePage::RadonDiff");
    if (update_page_option.update_first_time) {
      PerfCollector::GetInstance().StartRecord(
          proxy_->client_->GetTraceId(), PerfCollector::Perf::DIFF_ROOT_CREATE);
      PerfCollector::GetInstance().RecordPerfTime(
          proxy_->client_->GetTraceId(),
          PerfCollector::PerfStamp::DIFF_ROOT_START);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_CREATE_VDOM_START);
      lepus::Value p1(this);
      lepus::Value p2(true);
      lepus::Value p3(data_);
      std::string ss = "$renderPage" + std::to_string(this->node_index_);
      radon_children_.clear();
      dispatched_ = false;
      // Before lynx 2.1, $renderPage accept only the previous two params.
      context_->Call(ss, {p1, p2, p3});
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_CREATE_VDOM_END);
      // when the page is first updated
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_DISPATCH_START);
      if (!proxy_->HasSSRRadonPage() && !proxy_->IsServerSideRendering()) {
        page_proxy_->element_manager()
            ->painting_context()
            ->MarkUIOperationQueueFlushTiming(
                tasm::TimingKey::SETUP_UI_OPERATION_FLUSH_START, "");
      }
      DispatchForDiff(option);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::SETUP_DISPATCH_END);
      PerfCollector::GetInstance().RecordPerfTime(
          proxy_->client_->GetTraceId(),
          PerfCollector::PerfStamp::DIFF_ROOT_END);
      PerfCollector::GetInstance().EndRecord(
          proxy_->client_->GetTraceId(), PerfCollector::Perf::DIFF_ROOT_CREATE);
    } else if (need_update) {
      PerfCollector::GetInstance().StartRecord(
          proxy_->client_->GetTraceId(), PerfCollector::Perf::DIFF_SAME_ROOT);

      PerfCollector::GetInstance().RecordPerfTime(
          proxy_->client_->GetTraceId(), PerfCollector::PerfStamp::START_DIFF);
      // no first screen, check shouldComponent update
      if (!should_component_update) {
        LOGI("should_component_update is false in RadonPage::UpdatePage.");
        return need_update;
      }
      timing_flag = tasm::GetTimingFlag(table);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_CREATE_VDOM_START);
      /*
       * original_radon_children will save the original children of a radon
       * page. After finishing rendering new page, do diff on
       * original_radon_children and new radon_children_ of the radon_page
       */
      auto original_radon_children = std::move(radon_children_);
      radon_children_.clear();
      option.force_diff_entire_tree_ = update_page_option.reload_template;
      option.use_new_component_data_ = update_page_option.reload_template;
      option.refresh_lifecycle_ = update_page_option.reload_template;
      option.global_properties_changed_ =
          update_page_option.global_props_changed;
      lepus::Value p1(this);
      // No need to render subTree recursively.
      // SubComponent will render by itself during diff.
      lepus::Value p2(false);
      lepus::Value p3(data_);
      std::string ss = "$renderPage" + std::to_string(this->node_index_);
      // Before lynx 2.1, $renderPage accept only the previous two params.
      context_->Call(ss, {p1, p2, p3});
      if (element() != nullptr) {
        EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeSetted());
      }
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_CREATE_VDOM_END);
      page_proxy_->element_manager()
          ->painting_context()
          ->MarkUIOperationQueueFlushTiming(
              tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_START, timing_flag);
      PreHandlerCSSVariable();
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_DISPATCH_START);
      RadonMyersDiff(original_radon_children, option);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_DISPATCH_END);
      PerfCollector::GetInstance().EndRecord(
          proxy_->client_->GetTraceId(), PerfCollector::Perf::DIFF_SAME_ROOT);

      PerfCollector::GetInstance().RecordPerfTime(
          proxy_->client_->GetTraceId(), PerfCollector::PerfStamp::END_DIFF);
    }
  }
  OnReactComponentDidUpdate(option);
  TriggerComponentLifecycleUpdate(BaseComponent::kAttached);

  PipelineOptions pipeline_options;
  pipeline_options.timing_flag = timing_flag;
  pipeline_options.is_first_screen = update_page_option.update_first_time;
  pipeline_options.has_patched = option.has_patched_;
  pipeline_options.native_update_data_order_ =
      update_page_option.native_update_data_order_;
  if (proxy_->IsRadonDiff() && !proxy_->HasSSRRadonPage() &&
      !proxy_->IsServerSideRendering()) {
    page_proxy_->element_manager()->OnPatchFinishFromRadon(option.has_patched_,
                                                           pipeline_options);
  } else if (!proxy_->IsRadonDiff()) {
    /*
     * in radon mode, hsa_patched_ flag may be changed in update function (tt:if
     * and tt:for). But we can't modify has_patched_ flag in update function
     * now. Here we call OnPatchFinishInner manually to avoid some bad case.
     */
    page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  }
  TriggerComponentLifecycleUpdate(BaseComponent::kReady);
  SetInvalidated(false);
  return need_update;
}

#if LYNX_ENABLE_TRACING
std::string RadonPage::ConcatUpdateDataInfo(const RadonComponent *comp,
                                            const lepus::Value &table) const {
  /* Concatenate all the keys in updating data */
  std::stringstream ss;
  if (comp->IsRadonPage()) {
    ss << "Update Root Component: ";
  } else {
    ss << "component_name: " << comp->name().str();
  }
  ss << "       Keys: ";
  ForEachLepusValue(
      table, [&ss](const lepus::Value &key, const lepus::Value &val) {
        if (key.String()->str() != REACT_NATIVE_STATE_VERSION_KEY &&
            key.String()->str() != REACT_JS_STATE_VERSION_KEY) {
          ss << key.String()->str() << ",";
        }
      });
  return ss.str();
}
#endif

void RadonPage::DispatchSelf(const DispatchOption &option) {
  if (!page_proxy_->GetPageElementEnabled() && option.need_update_element_ &&
      !option.ssr_hydrating_ && CreateElementIfNeeded()) {
    page_proxy_->element_manager()->SetRootOnLayout(element()->layout_node());
    page_proxy_->element_manager()->catalyzer()->set_root(element());
    page_proxy_->element_manager()->SetRoot(element());
    option.has_patched_ = true;
    DispatchFirstTime();
  } else if (option.ssr_hydrating_) {
    AttachSSRPageElement(page_proxy_->SSRPage());
    page_proxy_->element_manager()->SetRoot(this->element());
  }
}

void RadonPage::Dispatch(const DispatchOption &option) {
  RadonNode::Dispatch(option);
}

void RadonPage::DispatchForDiff(const DispatchOption &option) {
  RadonNode::DispatchForDiff(option);
}

bool RadonPage::RefreshWithGlobalProps(const lynx::lepus::Value &table,
                                       bool should_render) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RefreshWithGlobalProps",
              [&should_render](lynx::perfetto::EventContext ctx) {
                auto *debug = ctx.event()->add_debug_annotations();
                debug->set_name("should_render");
                debug->set_bool_value(should_render);
              });
  if (!context_) {
    return false;
  }
  DCHECK(table.IsObject());

  auto data = lepus::Value(lepus::Dictionary::Create());
  UpdatePageOption update_page_option;
  update_page_option.from_native = true;
  update_page_option.global_props_changed = true;

  // update globalProps to topVar unconditionally.
  context_->UpdateTopLevelVariable(kGlobalPropsKey, table);

  if (!NeedsExtraData()) {
    if (should_render) {
      // this is called by native update global props
      // should call UpdatePage with empty data
      // with global_props_changed=true, inner UpdatePage will trigger children
      // render
      UpdatePage(data, update_page_option);
    }
    return true;
  }

  if (should_render) {
    // needs set global props to data here
    data.SetProperty(kGlobalPropsKey, table);
    UpdatePage(data, update_page_option);
  } else {
    UpdatePageData(kGlobalPropsKey, table);
  }
  return true;
}

bool RadonPage::PrePageRender(const lepus::Value &data) {
  return IsReact() ? PrePageRenderReact(data) : PrePageRenderTT(data);
}

bool RadonPage::PrePageRenderReact(const lepus::Value &data) {
  switch (render_type_) {
    case RenderType::FirstRender: {
      lepus::Value merged_data = lepus::Value(lepus::Dictionary::Create());
      ForcePreprocessPageData(data, merged_data);

      proxy_->OnReactCardRender(merged_data, true);
      return true;
    }
    case RenderType::UpdateByNativeList:
    case RenderType::UpdateByNative: {
      lepus::Value merged_data = lepus::Value(lepus::Dictionary::Create());
      ForcePreprocessPageData(data, merged_data);

      // Add extra version fields when there could be conflicts for native
      // and JS to update data simultaneously. For top level pages this could
      // happen when updating data by native.
      AttachDataVersions(merged_data);

      bool should_component_update = ShouldComponentUpdate();

      proxy_->OnReactCardRender(merged_data, should_component_update);
      return should_component_update;
    }
    case RenderType::UpdateFromJSBySelf: {
      return true;
    }
    default:
      break;
  }
  return true;
}

bool RadonPage::PrePageRenderTT(const lepus::Value &data) {
  if (render_type_ == RenderType::UpdateFromJSBySelf) {
    // update from js, no need to call `getDerivedStateFromProps`
    return ShouldComponentUpdate();
  }
  lepus_value new_data;
  if (get_derived_state_from_props_function_.IsCallable()) {
    new_data = PreprocessData();
    if (new_data.IsObject()) {
      UpdateTable(data_, new_data);
      LOGI("getDerivedStateFromProps for TTML Page ");
    }
  }

  // check shouldComponentUpdate
  return render_type_ == RenderType::FirstRender || ShouldComponentUpdate();
}

bool RadonPage::ForcePreprocessPageData(const lepus::Value &updated_data,
                                        lepus::Value &merged_data) {
  bool need_update = false;
  if (updated_data.IsObject()) {
    merged_data = lepus_value::ShallowCopy(updated_data);
  }
  if (get_derived_state_from_props_function_.IsCallable()) {
    lepus_value new_data = PreprocessData();
    if (new_data.IsObject()) {
      ForEachLepusValue(
          new_data, [this, &merged_data, &need_update](
                        const lepus::Value &key, const lepus::Value &value) {
            if (UpdatePageData(key.String()->str(), value)) {
              merged_data.SetProperty(key.String()->str(), value);
              need_update = true;
            }
          });
    }
  }

  return need_update;
}

bool RadonPage::UpdatePageData(const std::string &name,
                               const lepus::Value &value,
                               const bool update_top_var) {
  // issue:#3257 getDerivedStateFromProps lifecycle use the state of page。
  // can't get All the data from context's TopLevelVariable。so we also save
  // data in "data_"
  if (ShouldKeepPageData()) {
    data_.SetProperty(name, value);
  }
  // if already saved pageData. no need to update top_var.
  bool result = true;
  if (!enable_save_page_data_ || update_top_var) {
    result = context_->UpdateTopLevelVariable(name, value);
  }
  return result;
}

bool RadonPage::ResetPageData() {
  bool need_update = false;
  if (ShouldKeepPageData()) {
    // enableKeepPageData: true
    data_ = lepus::Value::Clone(init_data_);
    need_update = true;
    // lepus top level variables like __globalProps and SystemInfo may be
    // incorrectly changed by data processor
    UpdateLepusTopLevelVariableToData();
  } else {
    if (dsl_ == PackageInstanceDSL::REACT) {
      // EnablePageData in default true in later ReactLynx Versions.
      // In before Versions, global variables won't be cleared in ReactLynx.
      return false;
    }
    context_->ResetTopLevelVariable();
    ForEachLepusValue(
        init_data_, [this, &need_update](const lepus::Value &key,
                                         const lepus::Value &value) {
          need_update =
              context_->UpdateTopLevelVariable(key.String()->c_str(), value);
        });
  }
  return need_update;
}

bool RadonPage::ShouldKeepPageData() {
  return enable_save_page_data_ ||
         get_derived_state_from_props_function_.IsCallable() ||
         should_component_update_function_.IsCallable() ||
         (page_proxy_ && page_proxy_->IsServerSideRendering());
}

void RadonPage::UpdateSystemInfo(const lepus::Value &info) {
  if (NeedsExtraData()) {
    UpdatePageData(kSystemInfo, info, true);
  } else {
    // if no needs for set SystemInfo to page's data
    // only update top level variable
    // but component may needs extra data, so it's required to iterate over all
    // components
    context_->UpdateTopLevelVariable(kSystemInfo, info);
  }

  auto it = proxy_->component_map_.begin();
  for (; it != proxy_->component_map_.end(); ++it) {
    it->second->UpdateSystemInfo(info);
  }
}

void RadonPage::RefreshWithNewStyle(const DispatchOption &option) {
#if ENABLE_HMR
  if (proxy_->IsRadonDiff()) {
    PreHandlerCSSVariable();

    // execute style diff
    LightDiffForStyle(radon_children_, option);

    PipelineOptions pipeline_options;
    page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
    SetInvalidated(false);
  }
#endif
}

void RadonPage::Refresh(const DispatchOption &option) {
  this->Reset();
  if (!proxy_->IsRadonDiff()) {
    lepus::Value p1(this);
    lepus::Value p2(data_);
    std::string ss = "$updatePage0";
    // Before lynx 2.1, $updatePage0 accept only the previous one param.
    context_->Call(ss, {p1, p2});
    page_proxy_->is_updating_config_ = false;
    Dispatch(option);
  } else {
    auto original_radon_children = std::move(radon_children_);
    radon_children_.clear();
    lepus::Value p1(this);
    lepus::Value p2(false);
    lepus::Value p3(data_);
    std::string ss = "$renderPage" + std::to_string(this->node_index_);
    // Before lynx 2.1, $renderPage accept only the previous two params.
    context_->Call(ss, {p1, p2, p3});
    PreHandlerCSSVariable();
    RadonMyersDiff(original_radon_children, option);
  }
  PipelineOptions pipeline_options;
  page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  SetInvalidated(false);
}

void RadonPage::SetCSSVariables(const std::string &component_id,
                                const std::string &id_selector,
                                const lepus::Value &properties) {
  LOGI("start SetProperty from js id: " << component_id);
  if (component_id == PAGE_ID) {
    set_variable_ops_.emplace_back(SetCSSVariableOp(id_selector, properties));
    DispatchOption dispatch_option(proxy_);
    dispatch_option.css_variable_changed_ = true;
    Refresh(dispatch_option);
  } else {
    int comp_id;
    if (lynx::base::StringToInt(component_id, &comp_id, 10)) {
      if (page_proxy_->CheckComponentExists(comp_id)) {
        auto *component = proxy_->component_map_[comp_id];
        if (component) {
          component->SetCSSVariables(id_selector, properties);
        }
      } else {
        LOGE("js SetProperty with UnExisted Component!!");
      }
    }
  }
  LOGI("end SetProperty from js id: " << component_id);
}

CSSFragment *RadonPage::GetStyleSheetBase(AttributeHolder *holder) {
  if (!style_sheet_) {
    if (!intrinsic_style_sheet_ && style_sheet_manager_ != nullptr) {
      intrinsic_style_sheet_ =
          style_sheet_manager_->GetCSSStyleSheetForPage(mould_->css_id());
    }
    style_sheet_ =
        std::make_shared<CSSFragmentDecorator>(intrinsic_style_sheet_);
    if (intrinsic_style_sheet_ && style_sheet_ &&
        intrinsic_style_sheet_->HasTouchPseudoToken()) {
      style_sheet_->MarkHasTouchPseudoToken();
    }
    PrepareComponentExternalStyles(holder);
    PrepareRootCSSVariables(holder);
  }
  return style_sheet_.get();
}

bool RadonPage::UpdateConfig(const lepus::Value &config, bool to_refresh) {
  if (!context_) {
    return false;
  }

  UpdateSystemInfo(GenerateSystemInfo(&config));

  if (!to_refresh) {
    return false;
  }
  page_proxy_->is_updating_config_ = true;
  DispatchOption dispatch_option{page_proxy_};
  this->Reset();
  if (!proxy_->IsRadonDiff()) {
    // using radon
    lepus::Value p1(this);
    lepus::Value p2(data_);
    std::string ss = "$updatePage0";
    // Before lynx 2.1, $updatePage0 accept only the previous two params.
    context_->Call(ss, {p1, p2});
    page_proxy_->is_updating_config_ = false;
    Dispatch(dispatch_option);
  } else {
    // using radon diff
    auto original_radon_children = std::move(radon_children_);
    radon_children_.clear();
    lepus::Value p1(this);
    lepus::Value p2(false);
    lepus::Value p3(data_);
    std::string ss = "$renderPage" + std::to_string(this->node_index_);
    // Before lynx 2.1, $renderPage accept only the previous two params.
    context_->Call(ss, {p1, p2, p3});
    PreHandlerCSSVariable();
    page_proxy_->is_updating_config_ = false;
    dispatch_option.force_diff_entire_tree_ = true;
    RadonMyersDiff(original_radon_children, dispatch_option);
  }
  PipelineOptions pipeline_options;

  if (proxy_->IsRadonDiff()) {
    page_proxy_->element_manager()->OnPatchFinishFromRadon(
        dispatch_option.has_patched_, pipeline_options);
  } else {
    /*
     * in radon mode, hsa_patched_ flag may be changed in update function (tt:if
     * and tt:for). But we can't modify has_patched_ flag in update function
     * now. Here we call OnPatchFinishInner manually to avoid some bad case.
     */
    page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  }
  SetInvalidated(false);
  return true;
}

void RadonPage::OnReactComponentDidUpdate(const DispatchOption &option) {
  if (IsReact() && !option.ignore_component_lifecycle_) {
    proxy_->OnReactCardDidUpdate();
  }
}

void RadonPage::TriggerComponentLifecycleUpdate(const std::string name) {
  if (page_proxy_ && page_proxy_->GetComponentLifecycleAlignWithWebview()) {
    for (BaseComponent *component : radon_component_dispatch_order_) {
      if (!proxy_->CheckComponentExists(component->ComponentId())) {
        LOGI(
            "component doesn't exist in "
            "RadonPage::TriggerComponentLifecycleUpdate");
        continue;
      }
      page_proxy_->FireComponentLifecycleEvent(name, component);
    }
  }
}

void RadonPage::ResetComponentDispatchOrder() {
  if (page_proxy_ && page_proxy_->GetComponentLifecycleAlignWithWebview()) {
    radon_component_dispatch_order_.clear();
  }
}

void RadonPage::CollectComponentDispatchOrder(RadonBase *radon_node) {
  if (page_proxy_ && page_proxy_->GetComponentLifecycleAlignWithWebview() &&
      radon_node->IsRadonComponent()) {
    RadonComponent *radon_component = static_cast<RadonComponent *>(radon_node);
    radon_component_dispatch_order_.push_back(radon_component);
  }
}

const std::string &RadonPage::GetEntryName() const { return entry_name_; }

void RadonPage::OnScreenMetricsSet(float &width, float &height) {
  if (get_override_screen_metrics_function_.IsCallable()) {
    const std::string width_arg = "width";
    const std::string height_arg = "height";
    auto input = lepus::Dictionary::Create();
    input->SetValue(
        width_arg,
        lepus::Value(
            width *
            starlight::ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT));
    input->SetValue(
        height_arg,
        lepus::Value(
            height *
            starlight::ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT));

    auto result = context_->CallWithClosure(
        get_override_screen_metrics_function_, {lepus::Value(input)});
    bool result_valid = false;

    if (result.IsObject()) {
      if (result.Contains(width_arg) && result.Contains(height_arg)) {
        auto width_res = result.GetProperty(width_arg);
        auto height_res = result.GetProperty(height_arg);
        if (width_res.IsNumber() && height_res.IsNumber()) {
          width = width_res.Number() /
                  starlight::ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT;
          height = height_res.Number() /
                   starlight::ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT;
          result_valid = true;
        }
      }
    }
    if (!result_valid) {
      LOGE(
          "getScreenMetricsOverride should return table with width and height "
          "fields as numbers!!");
    }
  }
}

void RadonPage::SetScreenMetricsOverrider(const lepus::Value &overrider) {
  get_override_screen_metrics_function_ = overrider;
}

void RadonPage::Hydrate() {
  if (!page_proxy_->HasSSRRadonPage()) {
    return;
  }

  if (!page_proxy_->IsRadonDiff()) {
    // TODO: To support radon, we need to move elements to csr radon page and
    // trigger the style diff.
    LynxWarning(false, LYNX_ERROR_CODE_SSR_DECODE,
                "SSR currently does not support radon.");
    return;
  }

  DispatchOption dispatch_option{page_proxy_};
  dispatch_option.has_patched_ = true;
  dispatch_option.ssr_hydrating_ = true;
  dispatch_option.need_update_element_ = true;
  dispatch_option.need_diff_ = !page_proxy_->HydrateDataIdenticalAsSSR();
  PreHandlerCSSVariable();

  auto old_radon_children = std::move(page_proxy_->SSRPage()->radon_children_);
  DispatchSelf(dispatch_option);
  RadonMyersDiff(old_radon_children, dispatch_option);

  auto *root_element = page_proxy_->Page()->element();
  // Destory ssr page after hydrate.
  page_proxy_->ResetSSRPage();
  page_proxy_->element_manager()->SetRoot(root_element);

  PipelineOptions options;
  page_proxy_->element_manager()->OnPatchFinishFromRadon(true, options);
}

}  // namespace tasm
}  // namespace lynx
