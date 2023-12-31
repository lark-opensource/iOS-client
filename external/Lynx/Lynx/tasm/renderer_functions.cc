// Copyright 2020 The Lynx Authors. All rights reserved.

#include "tasm/renderer_functions.h"

#include <assert.h>

#include <deque>
#include <memory>
#include <sstream>
#include <utility>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/log/logging.h"
#include "base/ref_counted.h"
#include "base/string/string_number_convert.h"
#include "base/string/string_utils.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_style_sheet_manager.h"
#include "lepus/array.h"
#include "lepus/builtin.h"
#include "lepus/string_util.h"
#include "tasm/base/base_def.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_diff_list_node.h"
#include "tasm/radon/radon_diff_list_node2.h"
#include "tasm/radon/radon_dynamic_component.h"
#include "tasm/radon/radon_factory.h"
#include "tasm/radon/radon_for_node.h"
#include "tasm/radon/radon_if_node.h"
#include "tasm/radon/radon_list_node.h"
#include "tasm/radon/radon_node.h"
#include "tasm/radon/radon_page.h"
#include "tasm/react/element_manager.h"
#include "tasm/react/event.h"
#include "tasm/react/fiber/fiber_element.h"
#include "tasm/react/fiber/image_element.h"
#include "tasm/react/fiber/list_element.h"
#include "tasm/react/fiber/none_element.h"
#include "tasm/react/fiber/page_element.h"
#include "tasm/react/fiber/raw_text_element.h"
#include "tasm/react/fiber/scroll_element.h"
#include "tasm/react/fiber/text_element.h"
#include "tasm/react/fiber/view_element.h"
#include "tasm/react/fiber/wrapper_element.h"
#include "tasm/renderer.h"
#include "tasm/selector/fiber_element_selector.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

#if ENABLE_AIR
#include "tasm/air/air_element/air_block_element.h"
#include "tasm/air/air_element/air_component_element.h"
#include "tasm/air/air_element/air_element.h"
#include "tasm/air/air_element/air_for_element.h"
#include "tasm/air/air_element/air_if_element.h"
#include "tasm/air/air_element/air_page_element.h"
#include "tasm/air/air_element/air_radon_if_element.h"
#endif

#if defined(OS_WIN)
#ifdef SetProp
#undef SetProp
#endif  // SetProp
#endif  // OS_WIN

namespace lynx {
namespace tasm {

namespace {

template <class... Args>
void RenderFatal(bool result, const char* fmt, Args&&... a) {
  if (!result) {
    LOGF("LynxFatal error: error_code:"
         << LYNX_ERROR_CODE_DATA_BINDING << " error_message:"
         << lynx::base::FormatString(fmt, std::forward<Args>(a)...));
  }
}

template <class... Args>
void RenderWarning(bool result, const char* fmt, Args&&... a) {
  if (!result) {
    auto error = lynx::base::LynxError(LYNX_ERROR_CODE_DATA_BINDING, fmt,
                                       std::forward<Args>(a)...);
    lynx::base::ErrorStorage::GetInstance().SetError(std::move(error));
  }
}

lepus::Value GetSystemInfoFromTasm(TemplateAssembler* tasm) {
  auto config = tasm->page_proxy()->GetConfig();
  return GenerateSystemInfo(&config);
}

}  // namespace

#define RENDERER_FUNCTION_CC(name)                          \
  lepus::Value RendererFunctions::name(lepus::Context* ctx, \
                                       lepus::Value* argv, int argc)

#define CONVERT_ARG(name, index) lepus::Value* name = argv + index;

#define CHECK_ARGC_EQ(name, count) \
  RenderFatal(argc == count, #name " params size should == " #count);

#define CONVERT_ARG_AND_CHECK(name, index, Type, FunName) \
  lepus::Value* name = argv + index;                      \
  RenderFatal(name->Is##Type(),                           \
              #FunName " params " #index " type should use " #Type)

#define CHECK_ARGC_GE(name, now_argc) \
  RenderFatal(argc >= now_argc, #name " params size should >= " #now_argc)

#define ARGC() argc

#define CONVERT(v) (*v)

#define DCONVERT(v) ((v)->ToLepusValue())

#define RETURN(v) return (v)
#define RETURN_UNDEFINED() return lepus::Value();

#define LEPUS_CONTEXT() ctx

#define GET_IMPL_ID_AND_KEY(id, index_id, key, index_key, FuncName) \
  CONVERT_ARG_AND_CHECK(arg_id, index_id, Number, FuncName);        \
  CONVERT_ARG_AND_CHECK(arg_key, index_key, Number, FuncName);      \
  id = static_cast<int32_t>(arg_id->Number());                      \
  key = static_cast<uint64_t>(arg_key->Number());

/* Use this macro when fiber element is created. For example:
 ```
 auto& manager = self->page_proxy()->element_manager();
 auto element = manager->CreateFiberNode(arg0->String());

 ON_NODE_CREATE(element);
 RETURN(lepus::Value(element));
 ```
 */
#define ON_NODE_CREATE(node)                      \
  EXEC_EXPR_FOR_INSPECTOR(LEPUS_CONTEXT()         \
                              ->GetTasmPointer()  \
                              ->page_proxy()      \
                              ->element_manager() \
                              ->PrepareNodeForInspector(node.Get());)

/* Use this macro when fiber element is modified, including its attributes,
 inline styles, classes, id and so on. For example:
 ```
 auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
 element->SetAttribute(arg1->String(), *arg2);

 ON_NODE_MODIFIED(element);
 ```
 */
#define ON_NODE_MODIFIED(node) \
  EXEC_EXPR_FOR_INSPECTOR(     \
      LEPUS_CONTEXT()          \
          ->GetTasmPointer()   \
          ->page_proxy()       \
          ->element_manager()  \
          ->OnElementNodeSettedForInspector(node.Get(), node->data_model());)

/* Use this macro when fiber element is added to another fiber element. For
 example:
 ```
 auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
 auto child = static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());
 parent->InsertNode(child);

 ON_NODE_ADDED(child);
 RETURN(lepus::Value(child));
 ```
 */
#define ON_NODE_ADDED(node)                                                  \
  EXEC_EXPR_FOR_INSPECTOR(LEPUS_CONTEXT()                                    \
                              ->GetTasmPointer()                             \
                              ->page_proxy()                                 \
                              ->element_manager()                            \
                              ->CheckAndProcessSlotForInspector(node.Get()); \
                          LEPUS_CONTEXT()                                    \
                              ->GetTasmPointer()                             \
                              ->page_proxy()                                 \
                              ->element_manager()                            \
                              ->OnElementNodeAddedForInspector(node.Get());)

/* Use this macro when fiber element is removed from the parent. For example:
 ```
 auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
 auto child = static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());
 parent->RemoveNode(child);

 ON_NODE_REMOVED(child);
 RETURN(lepus::Value(child));
 ```
 */
#define ON_NODE_REMOVED(node)                     \
  EXEC_EXPR_FOR_INSPECTOR(LEPUS_CONTEXT()         \
                              ->GetTasmPointer()  \
                              ->page_proxy()      \
                              ->element_manager() \
                              ->OnElementNodeRemovedForInspector(node.Get());)

template <class T, class U>
base::scoped_refptr<T> static_scoped_pointer_cast(
    const base::scoped_refptr<U>& r) {
  auto p = static_cast<typename base::scoped_refptr<T>::element_type*>(r.Get());
  return base::scoped_refptr<T>{p};
}

RENDERER_FUNCTION_CC(IndexOf) {
  CHECK_ARGC_EQ(IndexOf, 2);
  CONVERT_ARG(obj, 0);
  CONVERT_ARG_AND_CHECK(idx, 1, Number, IndexOf);

  int index = idx->Number();
  RETURN(obj->GetProperty(index));
}

RENDERER_FUNCTION_CC(GetLength) {
  CHECK_ARGC_EQ(GetLength, 1);
  CONVERT_ARG(value, 0);
  int len = value->GetLength();
  RETURN(lepus::Value(len));
}

RENDERER_FUNCTION_CC(SetValueToMap) {
  CHECK_ARGC_EQ(SetValueToMap, 3);
  CONVERT_ARG_AND_CHECK(obj, 0, Object, SetValueToMap);
  CONVERT_ARG_AND_CHECK(key, 1, String, SetValueToMap);
  CONVERT_ARG(value, 2);
  lepus::String l_key = key->String();
  obj->SetProperty(l_key, *value);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AttachPage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AttachPage");
  LOGI("AttachPage" << ctx);
  CHECK_ARGC_EQ(AttachPage, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AttachPage);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AttachPage);
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg0->CPoint());
  RadonBase* base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  if (!base->IsRadonPage()) {
    RETURN_UNDEFINED();
  }
  RadonPage* root = static_cast<RadonPage*>(base);
  self->page_proxy()->SetRadonPage(root);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CreateVirtualNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateVirtualNode");
  CHECK_ARGC_GE(CreateVirtualNode, 1);
  CONVERT_ARG_AND_CHECK(name_val, 0, String, CreateVirtualNode);
  int eid = -1;
  if (argc > 1) {
    CONVERT_ARG_AND_CHECK(eid_val, 1, Number, CreateVirtualNode);
    eid = static_cast<int>(eid_val->Number());
  }
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  lynx::base::scoped_refptr<lepus::StringImpl> tag_name = name_val->String();
  auto* node = new lynx::tasm::RadonNode(tasm->page_proxy(), tag_name, eid);
  RETURN(lepus::Value(static_cast<RadonBase*>(node)));
}

RENDERER_FUNCTION_CC(CreateVirtualPage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateVirtualPage");

  // notify devtool page is updated
  EXEC_EXPR_FOR_INSPECTOR(LEPUS_CONTEXT()
                              ->GetTasmPointer()
                              ->page_proxy()
                              ->element_manager()
                              ->OnDocumentUpdated());

  CHECK_ARGC_EQ(CreateVirtualPage, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, CreateVirtualPage);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateVirtualPage);

  int tid = static_cast<int>(arg0->Number());
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  auto it = self->page_moulds().find(tid);
  DCHECK(it != self->page_moulds().end());
  PageMould* pm = it->second.get();
  auto entries_map = self->template_entries();
  auto iter = entries_map.find(tasm::DEFAULT_ENTRY_NAME);
  if (iter != entries_map.end()) {
    auto entry = iter->second;
    if (entry) {
      self->page_proxy()->SetCSSScopeEnabled(
          entry->compile_options().enable_remove_css_scope_);
    }
  }

  bool keep_page_data = self->page_proxy()->GetEnableSavePageData();
  self->page_proxy()->SetRadonDiff(true);
  RadonPage* page = new lynx::tasm::RadonPage(
      self->page_proxy(), tid, nullptr,
      self->style_sheet_manager(tasm::DEFAULT_ENTRY_NAME), pm, LEPUS_CONTEXT());
  if (page && !keep_page_data) {
    page->DeriveFromMould(pm);
  }
  page->SetGetDerivedStateFromPropsProcessor(
      self->GetProcessorWithName(REACT_PRE_PROCESS_LIFECYCLE));
  if (self->GetPageDSL() == PackageInstanceDSL::REACT) {
    page->SetDSL(PackageInstanceDSL::REACT);
    page->SetGetDerivedStateFromErrorProcessor(
        self->GetProcessorWithName(REACT_ERROR_PROCESS_LIFECYCLE));
  }
  page->SetScreenMetricsOverrider(
      self->GetProcessorWithName(SCREEN_METRICS_OVERRIDER));
  page->SetEnableSavePageData(keep_page_data);
  page->SetShouldComponentUpdateProcessor(
      self->GetProcessorWithName(REACT_SHOULD_COMPONENT_UPDATE));

  bool enable_check_data_when_update_page =
      self->page_proxy()->GetEnableCheckDataWhenUpdatePage();
  page->SetEnableCheckDataWhenUpdatePage(enable_check_data_when_update_page);

  RETURN(lepus::Value(page));
}

RENDERER_FUNCTION_CC(CreateVirtualComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateVirtualComponent");
  CHECK_ARGC_GE(CreateVirtualComponent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, CreateVirtualComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateVirtualComponent);

  int tid = static_cast<int>(arg0->Number());
  int component_instance_id = 0;
  if (ARGC() > 4) {
    CONVERT_ARG_AND_CHECK(arg4, 4, Number, CreateVirtualComponent);
    component_instance_id = static_cast<int>(arg4->Number());
  }

  lepus::Context* context = ctx;
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  auto cm_it = self->component_moulds(context).find(tid);
  assert(cm_it != self->component_moulds(context).end());
  ComponentMould* cm = cm_it->second.get();
  BaseComponent* component = nullptr;
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  auto comp = new RadonComponent(tasm->page_proxy(), tid, nullptr,
                                 self->style_sheet_manager(context), cm,
                                 context, component_instance_id);
  comp->SetDSL(self->GetPageConfig()->GetDSL());
  component = static_cast<BaseComponent*>(comp);
  if (ARGC() > 2) {
    CONVERT_ARG_AND_CHECK(arg2, 2, String, CreateVirtualComponent);
    component->SetName(arg2->String());
  }
  if (ARGC() > 3) {
    CONVERT_ARG_AND_CHECK(arg3, 3, String, CreateVirtualComponent);
    component->SetPath(arg3->String());
  } else {
    component->SetPath(lynx::lepus::StringImpl::Create(cm->path()));
  }

  auto globalProps = self->GetGlobalProps();
  if (!globalProps.IsNil()) {
    component->UpdateGlobalProps(globalProps);
  }

  if (component->dsl() == PackageInstanceDSL::REACT) {
    component->SetGetDerivedStateFromErrorProcessor(
        self->GetComponentProcessorWithName(component->path().c_str(),
                                            REACT_ERROR_PROCESS_LIFECYCLE,
                                            LEPUS_CONTEXT()->name()));
  }

  component->SetGetDerivedStateFromPropsProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_PRE_PROCESS_LIFECYCLE,
                                          LEPUS_CONTEXT()->name()));

  component->SetShouldComponentUpdateProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_SHOULD_COMPONENT_UPDATE,
                                          LEPUS_CONTEXT()->name()));
  UpdateComponentConfig(self, component);
  auto* base = static_cast<RadonBase*>(static_cast<RadonComponent*>(component));
  RETURN(lepus::Value(base));
}

RENDERER_FUNCTION_CC(AppendChild) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AppendChild");
  CHECK_ARGC_EQ(AppendChild, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AppendChild);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AppendChild);

  RadonBase* parent = reinterpret_cast<RadonBase*>(arg0->CPoint());
  RadonBase* child = reinterpret_cast<RadonBase*>(arg1->CPoint());
  parent->AddChild(std::unique_ptr<RadonBase>(child));
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AppendSubTree) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AppendSubTree");
  CHECK_ARGC_EQ(AppendChild, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AppendSubTree);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AppendSubTree);

  RadonBase* parent = reinterpret_cast<RadonBase*>(arg0->CPoint());
  RadonBase* sub_tree = reinterpret_cast<RadonBase*>(arg1->CPoint());
  parent->AddSubTree(std::unique_ptr<RadonBase>(sub_tree));
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CloneSubTree) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CloneSubTree");
  CHECK_ARGC_EQ(CloneSubTree, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, CloneSubTree);

  auto* to_be_copied = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* new_node = radon_factory::CopyRadonDiffSubTree(*to_be_copied);
  RETURN(lepus::Value(new_node));
}

RENDERER_FUNCTION_CC(SetAttributeTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetAttributeTo");
  CHECK_ARGC_EQ(SetAttributeTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetAttributeTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetAttributeTo);
  CONVERT_ARG(arg2, 2);
  auto key = arg1->String();
  lepus::Value value = CONVERT(arg2);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  base->SetLynxKey(key, value);
  if (base->IsRadonNode()) {
    auto* node = static_cast<RadonNode*>(base);
    node->SetDynamicAttribute(key, value);
  }
  //  TODO: Handle UpdateContextData for radon-diff
  //  constexpr char kContextPrefix[] = "context-";
  //  constexpr size_t kContextPrefixSize = 8;
  //  std::string key_str = key.Get()->c_str();
  //
  //  if (lepus::BeginsWith(key_str, kContextPrefix)) {
  //    size_t len = key_str.length();
  //    std::string context_key =
  //        key_str.substr(kContextPrefixSize, len - kContextPrefixSize);
  //    if (node->IsVirtualPlug()) {
  //      ((VirtualPlug*)node)->UpdateContextData(context_key, value);
  //    } else {
  //      if (!node->IsVirtualComponent()) {
  //        node = node->component();
  //      }
  //      ((VirtualComponent*)node)->UpdateContextData(context_key, value);
  //    }
  //  } else {
  //    node->SetDynamicAttribute(key, value);
  //  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetContextData) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetContextData");
  //  TODO: Handle SetContextData for radon-diff
  //  CHECK_ARGC_EQ(SetContextData, 3);
  //  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetContextData);
  //  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetContextData);
  //  CONVERT_ARG(arg2, 2);
  //
  //  VirtualNode* node = reinterpret_cast<VirtualNode*>(arg0->CPoint());
  //  auto key = arg1->String();
  //  lepus::Value value = CONVERT(arg2);
  //
  //  if (node->IsVirtualPlug()) {
  //    ((VirtualPlug*)node)->UpdateContextData(key, value);
  //  } else {
  //    if (!node->IsVirtualComponent()) {
  //      node = node->component();
  //    }
  //    ((VirtualComponent*)node)->UpdateContextData(key, value);
  //  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetStaticStyleTo2) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetStaticStyleTo2");
  CHECK_ARGC_EQ(SetStaticStyleTo2, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetStaticStyleTo2);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, SetStaticStyleTo2);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, SetStaticStyleTo2);
  CONVERT_ARG(arg3, 3);

  CSSPropertyID id =
      static_cast<CSSPropertyID>(static_cast<int>(arg1->Number()));
  if (CSSProperty::IsPropertyValid(id)) {
    CSSValuePattern pattern =
        static_cast<CSSValuePattern>(static_cast<int>(arg2->Number()));
    auto value = CONVERT(arg3);
    GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
        ->SetStaticInlineStyle(id, tasm::CSSValue(value, pattern));
  } else {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "Unknown css id: " + std::to_string(id));
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetScriptEventTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetScriptEventTo");

  if (LEPUS_CONTEXT()->IsLepusContext()) {
    LOGI("SetScriptEventTo failed since context is lepus context.");
    RETURN_UNDEFINED();
  }

  DCHECK(ARGC() >= 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetScriptEventTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetScriptEventTo);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, SetScriptEventTo);
  CONVERT_ARG(arg3, 3);
  CONVERT_ARG(arg4, 4);

  const auto& type = arg1->String();
  const auto& name = arg2->String();

  GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
      ->SetLepusEvent(type, name, *arg3, *arg4);
  RETURN_UNDEFINED();
}

ListComponentInfo RendererFunctions::ComponentInfoFromContext(
    lepus::Context* ctx, lepus::Value* argv, int argc) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ComponentInfoFromContext");
  CONVERT_ARG(name, 1);
  CONVERT_ARG(data, 2);
  CONVERT_ARG(props, 3);
  CONVERT_ARG(ids, 4);
  CONVERT_ARG(style, 5);
  CONVERT_ARG(clazz, 6);
  CONVERT_ARG(event, 7);
  CONVERT_ARG(dataset, 8);

  lepus::Value comp_type = lepus::Value();
  if (ARGC() > 9) {
    CONVERT_ARG(arg9, 9);
    comp_type = *arg9;
  } else {
    comp_type.SetString(lynx::lepus::StringImpl::Create("default"));
  }

  ListComponentInfo info(name->String()->str(), LEPUS_CONTEXT()->name(),
                         CONVERT(data), CONVERT(props), CONVERT(ids),
                         CONVERT(style), CONVERT(clazz), *event,
                         CONVERT(dataset), CONVERT(&comp_type));
  return info;
}

RENDERER_FUNCTION_CC(AppendListComponentInfo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AppendListComponentInfo");
  CHECK_ARGC_GE(AppendListComponentInfo, 9);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AppendListComponentInfo);
  ListNode* list = nullptr;
  auto radon_list =
      static_cast<RadonListBase*>(reinterpret_cast<RadonBase*>(arg0->CPoint()));
  list = static_cast<ListNode*>(radon_list);

  ListComponentInfo info =
      RendererFunctions::ComponentInfoFromContext(ctx, argv, argc);
  list->AppendComponentInfo(info);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CreateVirtualPlug) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateVirtualPlug");
  CHECK_ARGC_EQ(CreateVirtualPlug, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, CreateVirtualPlug);
  lynx::base::scoped_refptr<lepus::StringImpl> tag_name = arg0->String();
  auto* plug = new RadonPlug(tag_name, nullptr);
  lepus::Value value(static_cast<RadonBase*>(plug));
  RETURN(value);
}

RENDERER_FUNCTION_CC(CreateVirtualPlugWithComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateVirtualPlugWithComponent");
  CHECK_ARGC_EQ(CreateVirtualPlugWithComponent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, CreateVirtualPlugWithComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateVirtualPlugWithComponent);
  lynx::base::scoped_refptr<lepus::StringImpl> tag_name = arg0->String();

  RadonComponent* comp = reinterpret_cast<RadonComponent*>(arg1->CPoint());
  auto* plug = new RadonPlug(tag_name, nullptr);
  lepus::Value value(static_cast<RadonBase*>(plug));
  plug->SetComponent(comp);
  RETURN(value);
}

RENDERER_FUNCTION_CC(MarkComponentHasRenderer) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "MarkComponentHasRenderer");
  CHECK_ARGC_EQ(MarkComponentHasRenderer, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, MarkComponentHasRenderer);
  // TODO(radon): radon diff support.
  // RadonComponent* component =
  //          reinterpret_cast<RadonComponent*>(arg0->CPoint());
  // component->MarkHasRendered();
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetStaticAttrTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetStaticAttrTo");
  CHECK_ARGC_EQ(SetStaticAttrTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetStaticAttrTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetStaticAttrTo);
  CONVERT_ARG(arg2, 2);
  auto key = arg1->String();
  auto value = CONVERT(arg2);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  base->SetLynxKey(key, value);
  GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
      ->SetStaticAttribute(key, value);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetStyleTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetStyleTo");
  CHECK_ARGC_EQ(SetStyleTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetStyleTo);
  CONVERT_ARG(arg1, 1);
  CONVERT_ARG(arg2, 2);

  RenderFatal(arg1->IsString() || arg1->IsNumber(),
              "SetStyleTo Params1 type error:%d",
              static_cast<int>(arg1->Type()));
  CSSPropertyID id;
  if (arg1->IsString()) {
    auto key = arg1->String();
    id = CSSProperty::GetPropertyID(key);
  } else {
    id = static_cast<CSSPropertyID>(static_cast<int>(arg1->Number()));
  }
  if (!arg2->IsString()) {
    RenderWarning(arg2->IsString(), "SetStyleTo %s Params2 type error",
                  CSSProperty::GetPropertyName(id).c_str());
    RETURN_UNDEFINED();
  }
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  auto value = arg2;
  if (CSSProperty::IsPropertyValid(id) && !value->String()->empty()) {
    GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
        ->SetInlineStyle(id, value->String(),
                         tasm->GetPageConfig()->GetCSSParserConfigs());
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetDynamicStyleTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetDynamicStyleTo");
  CHECK_ARGC_EQ(SetDynamicStyleTo, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetDynamicStyleTo);
  CONVERT_ARG(arg1, 1);

  if (!arg1->IsString()) {
    RETURN_UNDEFINED();
  }
  auto tmp_str = arg1->String();
  auto style_value = tmp_str->c_str();
  auto splits = base::SplitStringByCharsOrderly(style_value, {':', ';'});
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  for (size_t i = 0; i + 1 < splits.size(); i = i + 2) {
    std::string key = base::TrimString(splits[i]);
    std::string value = base::TrimString(splits[i + 1]);

    CSSPropertyID id = CSSProperty::GetPropertyID(key);
    if (CSSProperty::IsPropertyValid(id) && value.length() > 0) {
      GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
          ->SetInlineStyle(id, value,
                           tasm->GetPageConfig()->GetCSSParserConfigs());
    }
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetStaticStyleTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetStaticStyleTo");
  CHECK_ARGC_EQ(SetStaticStyleTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetStaticStyleTo);
  CONVERT_ARG(arg1, 1);
  CONVERT_ARG(arg2, 2);
  if (!arg2->IsString()) {
    RETURN_UNDEFINED();
  }
  CSSPropertyID id;
  if (arg1->IsString()) {
    auto key = arg1->String();
    id = CSSProperty::GetPropertyID(key);
  } else {
    id = static_cast<CSSPropertyID>(static_cast<int>(arg1->Number()));
  }
  auto value = arg2->String();
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  if (CSSProperty::IsPropertyValid(id) && !value->empty()) {
    GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
        ->SetStaticInlineStyle(id, value,
                               tasm->GetPageConfig()->GetCSSParserConfigs());
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetDataSetTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetDataSetTo");
  CHECK_ARGC_EQ(SetDataSetTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetDataSetTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetDataSetTo);
  CONVERT_ARG(arg2, 2);

  auto key = arg1->String();
  auto value = CONVERT(arg2);
  GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)->SetDataSet(key, value);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetStaticEventTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetStaticEventTo");
  CHECK_ARGC_EQ(SetDataSetTo, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetStaticEventTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetStaticEventTo);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, SetStaticEventTo);
  CONVERT_ARG_AND_CHECK(arg3, 3, String, SetStaticEventTo);

  auto type = arg1->String();
  auto name = arg2->String();
  auto value = arg3->String();
  GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)
      ->SetStaticEvent(type, name, value);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetClassTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetClassTo");
  CHECK_ARGC_EQ(SetClassTo, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetClassTo);
  CONVERT_ARG(arg1, 1);
  if (!arg1->IsString()) {
    RETURN_UNDEFINED();
  }

  auto clazz = arg1->String();
  if (clazz->empty()) RETURN_UNDEFINED();

  if (clazz->str().find(" ") == std::string::npos) {
    GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)->SetClass(clazz);
    RETURN_UNDEFINED();
  }

  std::vector<std::string> classes;
  if (!base::SplitString(clazz->str(), ' ', classes)) {
    RETURN_UNDEFINED();
  }

  for (const auto& class_name : classes) {
    auto cl = base::TrimString(class_name);
    if (!cl.empty()) {
      GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)->SetClass(cl);
    };
  }

  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetStaticClassTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetStaticClassTo");
  CHECK_ARGC_EQ(SetStaticClassTo, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetStaticClassTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetStaticClassTo);

  auto clazz = arg1->String();
  if (!clazz->empty()) {
    GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)->SetStaticClass(clazz);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetId) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetId");
  CHECK_ARGC_EQ(SetId, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetId);
  CONVERT_ARG(arg1, 1);

  // if arg1 is not a String, it will return empty string
  auto id = arg1->String();
  if (!id->empty()) {
    GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0)->SetIdSelector(id);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(UpdateComponentInfo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateComponentInfo");
  CHECK_ARGC_EQ(UpdateComponentInfo, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateComponentInfo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, UpdateComponentInfo);
  // CONVERT_ARG_AND_CHECK(arg2, 2, Array, UpdateComponentInfo);
  CONVERT_ARG(arg2, 2);
  CONVERT_ARG_AND_CHECK(arg3, 3, String, UpdateComponentInfo);
  auto* component_info_storage = GetBaseComponent(ctx, arg0);
  auto key = arg1->String();
  lepus::Value slot1 = DCONVERT(arg2);
  lepus::Value slot2 = DCONVERT(arg3);
  RenderFatal(slot1.IsArrayOrJSArray(),
              "UpdateComponentInfo: arg2 should be array");
  if (component_info_storage) {
    component_info_storage->component_info_map().SetProperty(key, slot1);
    component_info_storage->component_path_map().SetProperty(key, slot2);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(GetComponentInfo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetComponentInfo");
  CHECK_ARGC_EQ(GetComponentInfo, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, GetComponentInfo);
  auto* component_info_storage = GetBaseComponent(ctx, arg0);
  if (!component_info_storage) {
    RETURN_UNDEFINED();
  }
  lepus::Value ret(component_info_storage->component_info_map());
  RETURN(ret);
}

RENDERER_FUNCTION_CC(CreateSlot) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateSlot");
  CHECK_ARGC_EQ(CreateSlot, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, CreateSlot);

  lynx::base::scoped_refptr<lepus::StringImpl> tag_name = arg0->String();
  auto* slot = new RadonSlot(tag_name);
  lepus::Value value(slot);
  RETURN(value);
}

RENDERER_FUNCTION_CC(SetProp) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetProp");
  CHECK_ARGC_EQ(SetProp, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetProp);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetProp);
  CONVERT_ARG(arg2, 2);

  lepus::String key = arg1->String();
  auto* component = GetBaseComponent(LEPUS_CONTEXT(), arg0);
  if (!component) {
    RETURN_UNDEFINED();
  }
  auto holder = GetInternalAttributeHolder(LEPUS_CONTEXT(), arg0);
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  auto* radon_component = static_cast<RadonComponent*>(component);
  // lynx-key and removeComponentElement shouldn't be a property.
  // So if lynx-key has been setted successfully, we shouldn't SetProperties
  // then.
  if (!radon_component->SetSpecialComponentAttribute(key, *arg2)) {
    component->SetProperties(key, *arg2, holder,
                             tasm->GetPageConfig()->GetStrictPropType());
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetData) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetData");
  CHECK_ARGC_EQ(SetData, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetData);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetData);
  CONVERT_ARG(arg2, 2);
  lepus::String key = arg1->String();
  auto* component = GetBaseComponent(LEPUS_CONTEXT(), arg0);
  if (component) {
    component->SetData(key, *arg2);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AppendVirtualPlugToComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AppendVirtualPlugToComponent");
  CHECK_ARGC_EQ(AppendVirtualPlugToComponent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AppendVirtualPlugToComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AppendVirtualPlugToComponent);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* component = static_cast<RadonComponent*>(base);
  base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  auto* plug = static_cast<RadonPlug*>(base);
  plug->radon_component_ = component;
  component->AddRadonPlug(plug->plug_name(), std::unique_ptr<RadonBase>{plug});
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AddVirtualPlugToComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AddVirtualPlugToComponent");
  CHECK_ARGC_EQ(AddVirtualPlugToComponent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AddVirtualPlugToComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AddVirtualPlugToComponent);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* component = static_cast<RadonComponent*>(base);
  base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  auto* plug = static_cast<RadonPlug*>(base);
  plug->SetAttachedComponent(component);
  component->AddRadonPlug(plug->plug_name(), std::unique_ptr<RadonBase>{plug});
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AddFallbackToDynamicComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AddFallbackToDynamicComponent");
  CHECK_ARGC_EQ(AddFallbackToDynamicComponent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AddFallbackToDynamicComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AddFallbackToDynamicComponent);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* component = static_cast<RadonDynamicComponent*>(base);
  base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  auto* plug = static_cast<RadonPlug*>(base);
  plug->SetAttachedComponent(component);
  component->AddFallback(std::unique_ptr<RadonPlug>{plug});
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(GetComponentData) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetComponentData");
  CHECK_ARGC_EQ(GetComponentData, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, GetComponentData);
  auto* component = GetBaseComponent(LEPUS_CONTEXT(), arg0);
  if (component) {
    RETURN(lepus::Value(component->data()));
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(GetComponentProps) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetComponentProps");
  CHECK_ARGC_EQ(GetComponentProps, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, GetComponentProps);
  auto* component = GetBaseComponent(LEPUS_CONTEXT(), arg0);
  if (component) {
    RETURN(lepus::Value(component->properties()));
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(GetComponentContextData) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetComponentContextData");
  CHECK_ARGC_EQ(GetComponentContextData, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, GetComponentContextData);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, GetComponentContextData);
  // TODO: Handle GetComponentContextData

  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CreateComponentByName) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateComponentByName");
  CHECK_ARGC_EQ(CreateComponentByName, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, CreateComponentByName);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateComponentByName);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, CreateComponentByName);
  int component_instance_id = static_cast<int>(arg2->Number());
  lepus::Context* context = LEPUS_CONTEXT();
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  const std::string& name = arg0->String().Get()->str();
  auto iter = self->component_name_to_id(context).find(name);
  DCHECK(iter != self->component_name_to_id(context).end());
  int tid = iter->second;
  auto cm_it = self->component_moulds(context).find(tid);
  DCHECK(cm_it != self->component_moulds(context).end());
  ComponentMould* cm = cm_it->second.get();
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  auto component = new RadonComponent(tasm->page_proxy(), tid, nullptr,
                                      self->style_sheet_manager(context), cm,
                                      context, component_instance_id);
  component->SetDSL(self->GetPageConfig()->GetDSL());
  component->SetName(arg0->String());
  component->SetPath(lepus::StringImpl::Create(cm->path()));

  auto globalProps = self->GetGlobalProps();
  if (!globalProps.IsNil()) {
    component->UpdateGlobalProps(globalProps);
  }

  if (component->dsl() == PackageInstanceDSL::REACT) {
    component->SetGetDerivedStateFromErrorProcessor(
        self->GetComponentProcessorWithName(component->path().c_str(),
                                            REACT_ERROR_PROCESS_LIFECYCLE,
                                            LEPUS_CONTEXT()->name()));
  }

  component->SetGetDerivedStateFromPropsProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_PRE_PROCESS_LIFECYCLE,
                                          LEPUS_CONTEXT()->name()));
  component->SetShouldComponentUpdateProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_SHOULD_COMPONENT_UPDATE,
                                          LEPUS_CONTEXT()->name()));

  UpdateComponentConfig(self, component);
  auto* base = static_cast<RadonBase*>(static_cast<RadonComponent*>(component));
  RETURN(lepus::Value(base));
}

RENDERER_FUNCTION_CC(CreateDynamicVirtualComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateDynamicVirtualComponent");
  // Get Params
  CHECK_ARGC_GE(CreateDynamicVirtualComponent, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, CreateDynamicVirtualComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateDynamicVirtualComponent);
  CONVERT_ARG(arg2, 2);
  CONVERT_ARG_AND_CHECK(arg3, 3, Number, CreateDynamicVirtualComponent);
  if (!arg2->IsString()) {
    RenderWarning(arg2->IsString(),
                  "CreateDynamicVirtualComponent Params2 type error");
    RETURN_UNDEFINED();
  }

  int component_instance_id = static_cast<int>(arg3->Number());
  int tid = static_cast<int>(arg0->Number());
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  auto entry_name = arg2->String();
  lepus::Context* context = LEPUS_CONTEXT();
  const auto& url = self->GetTargetUrl(context->name(), entry_name->str());

  auto comp = new RadonDynamicComponent(self, url, self->page_proxy(), tid,
                                        component_instance_id);
  comp->SetDSL(self->GetPageConfig()->GetDSL());
  auto entry = self->RequireTemplateEntry(comp, url);

  if (entry != nullptr) {
    auto cm_it = entry->dynamic_component_moulds().find(0);
    if (cm_it != entry->dynamic_component_moulds().end()) {
      DynamicComponentMould* cm = cm_it->second.get();
      auto context = entry->GetVm().get();
      comp->InitDynamicComponent(nullptr, entry->GetStyleSheetManager(), cm,
                                 context);
      comp->SetGlobalProps(self->GetGlobalProps());
      comp->SetPath(lynx::lepus::StringImpl::Create(cm->path()));
      if (comp->dsl() == PackageInstanceDSL::REACT) {
        comp->SetGetDerivedStateFromErrorProcessor(
            self->GetComponentProcessorWithName(comp->path().c_str(),
                                                REACT_ERROR_PROCESS_LIFECYCLE,
                                                context->name()));
      }

      comp->SetGetDerivedStateFromPropsProcessor(
          self->GetComponentProcessorWithName(comp->path().c_str(),
                                              REACT_PRE_PROCESS_LIFECYCLE,
                                              context->name()));
      comp->SetShouldComponentUpdateProcessor(
          self->GetComponentProcessorWithName(comp->path().c_str(),
                                              REACT_SHOULD_COMPONENT_UPDATE,
                                              context->name()));
    } else {
      // something wrong with dynamic component template.js, maybe
      // TargetSdkVersion has not been setted.
      RenderWarning(
          false, "CreateDynamicVirtualComponent Failed, loadComponent Failed.");
      RETURN_UNDEFINED();
    }
  }

  BaseComponent* dynamic_component = nullptr;
  dynamic_component = static_cast<BaseComponent*>(comp);
  dynamic_component->SetName(entry_name);
  auto* base = static_cast<RadonBase*>(
      static_cast<RadonDynamicComponent*>(dynamic_component));
  RETURN(lepus::Value(base));
}

RENDERER_FUNCTION_CC(ProcessComponentData) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ProcessComponentData");
  CHECK_ARGC_EQ(ProcessComponentData, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, ProcessComponentData);
  RadonComponent* component = reinterpret_cast<RadonComponent*>(arg0->CPoint());
  component->PreRenderForRadonComponent();
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AppendRadonListComponentInfo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AppendRadonListComponentInfo");
  CHECK_ARGC_EQ(AppendRadonListComponentInfo, 10);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AppendRadonListComponentInfo);

  auto* list_node =
      static_cast<RadonListNode*>(reinterpret_cast<RadonBase*>(arg0->CPoint()));
  ListComponentInfo info =
      RendererFunctions::ComponentInfoFromContext(ctx, argv, argc);
  list_node->AppendComponentInfo(info);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetEventTo) {
  // TODO
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(RenderDynamicComponent) {
  CONVERT_ARG_AND_CHECK(arg0, 0, String, RenderDynamicComponent);
  std::string entry_name = arg0->String()->str();

  CONVERT_ARG_AND_CHECK(arg2, 2, CPointer, RenderDynamicComponent);
  RadonDynamicComponent* component = static_cast<RadonDynamicComponent*>(
      reinterpret_cast<RadonBase*>(arg2->CPoint()));

  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_RENDER_ENTRANCE,
              [entry_name](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("entry_name");
                debug->set_string_value(entry_name);
              });

  if (component->IsEmpty()) {
    // For radon diff, component may be empty,
    // that means target context has not been load,
    // check this case before rendering
    RETURN_UNDEFINED()
  }

  CHECK_ARGC_EQ(RenderDynamicComponent, 6);

  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, RenderDynamicComponent);
  CONVERT_ARG(arg3, 3);
  CONVERT_ARG(arg4, 4);
  CONVERT_ARG(arg5, 5);

  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());

  lepus::Context* context = LEPUS_CONTEXT();
  std::string url = self->GetTargetUrl(context->name(), entry_name);
  lepus::Context* target_context = self->context(url);
  std::stringstream ss;
  ss << "$renderEntranceDynamicComponent";

  target_context->Call(ss.str(), {*arg2, *arg3, *arg4, *arg5});
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(PushDynamicNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PushDynamicNode");
  CHECK_ARGC_GE(PushDynamicNode, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, PushDynamicNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, PushDynamicNode);

  auto* node = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* child = reinterpret_cast<RadonBase*>(arg1->CPoint());
  node->PushDynamicNode(child);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(GetDynamicNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetDynamicNode");
  CHECK_ARGC_GE(PushDynamicNode, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, GetDynamicNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, GetDynamicNode);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, GetDynamicNode);

  auto* node = reinterpret_cast<RadonBase*>(arg0->CPoint());
  uint32_t index = arg1->Number();
  uint32_t node_index = arg2->Number();
  RETURN(lepus::Value(node->GetDynamicNode(index, node_index)));
}

RENDERER_FUNCTION_CC(CreateRadonNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonNode");
  CHECK_ARGC_GE(CreateRadonNode, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, CreateRadonNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, CreateRadonNode);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, CreateRadonNode);

  uint32_t node_index = arg2->Number();
  TemplateAssembler* tasm = static_cast<TemplateAssembler*>(arg0->CPoint());
  lynx::base::scoped_refptr<lepus::StringImpl> tag_name = arg1->String();
  auto* page_proxy = tasm->page_proxy();
  RadonNode* node = new lynx::tasm::RadonNode(page_proxy, tag_name, node_index);
  lepus::Value value(static_cast<RadonBase*>(node));
  RETURN(value);
}

RENDERER_FUNCTION_CC(CreateRadonBlockNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonBlockNode");
  CHECK_ARGC_GE(CreateRadonBlockNode, 2);
  lepus::Value value(
      new lynx::tasm::RadonBase(kRadonBlock, "block", kRadonInvalidNodeIndex));
  RETURN(value);
}

RENDERER_FUNCTION_CC(AppendRadonChild) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AppendRadonChild");
  CHECK_ARGC_EQ(CreateRadonNode, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AppendRadonChild);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AppendRadonChild);
  RadonBase* parent = reinterpret_cast<RadonBase*>(arg0->CPoint());
  RadonBase* child = reinterpret_cast<RadonBase*>(arg1->CPoint());
  parent->AddChild(std::unique_ptr<RadonBase>(child));
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CreateRadonPage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonPage");

  // notify devtool page is updated
  EXEC_EXPR_FOR_INSPECTOR(LEPUS_CONTEXT()
                              ->GetTasmPointer()
                              ->page_proxy()
                              ->element_manager()
                              ->OnDocumentUpdated());

  CHECK_ARGC_EQ(CreateRadonPage, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, CreateRadonPage);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateRadonPage);

  int tid = static_cast<int>(arg0->Number());
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  auto it = self->page_moulds().find(tid);
  DCHECK(it != self->page_moulds().end());
  PageMould* pm = it->second.get();

  RadonPage* page = new lynx::tasm::RadonPage(
      self->page_proxy(), tid, nullptr,
      self->style_sheet_manager(tasm::DEFAULT_ENTRY_NAME), pm, LEPUS_CONTEXT());
  if (page && !self->page_proxy()->GetEnableSavePageData()) {
    page->DeriveFromMould(pm);
  }
  if (self->GetPageDSL() == PackageInstanceDSL::REACT) {
    page->SetDSL(PackageInstanceDSL::REACT);
    page->SetGetDerivedStateFromPropsProcessor(
        self->GetProcessorWithName(REACT_PRE_PROCESS_LIFECYCLE));
    page->SetGetDerivedStateFromErrorProcessor(
        self->GetProcessorWithName(REACT_ERROR_PROCESS_LIFECYCLE));
  }
  page->SetScreenMetricsOverrider(
      self->GetProcessorWithName(SCREEN_METRICS_OVERRIDER));
  page->SetEnableSavePageData(self->page_proxy()->GetEnableSavePageData());

  bool enable_check_data_when_update_page =
      self->page_proxy()->GetEnableCheckDataWhenUpdatePage();
  page->SetEnableCheckDataWhenUpdatePage(enable_check_data_when_update_page);

  page->SetShouldComponentUpdateProcessor(
      self->GetProcessorWithName(REACT_SHOULD_COMPONENT_UPDATE));
  RETURN(lepus::Value(page));
}

RENDERER_FUNCTION_CC(AttachRadonPage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AttachRadonPage");
  CHECK_ARGC_EQ(AttachRadonPage, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, CreateRadonPage);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateRadonPage);

  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg0->CPoint());
  RadonBase* base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  if (!base->IsRadonPage()) {
    RETURN_UNDEFINED();
  }
  RadonPage* root = static_cast<RadonPage*>(base);
  self->page_proxy()->SetRadonPage(root);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CreateIfRadonNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateIfRadonNode");
  CHECK_ARGC_GE(CreateIfRadonNode, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, CreateIfRadonNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, CreateIfRadonNode);

  uint32_t node_index = arg1->Number();
  auto* if_node = new lynx::tasm::RadonIfNode(node_index);
  lepus::Value value(static_cast<RadonBase*>(if_node));
  RETURN(value);
}

RENDERER_FUNCTION_CC(UpdateIfNodeIndex) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateIfNodeIndex");
  CHECK_ARGC_GE(UpdateIfNodeIndex, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateIfNodeIndex);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, UpdateIfNodeIndex);

  RadonBase* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (base->NodeType() != kRadonIfNode) {
    RETURN_UNDEFINED();
  }
  RadonIfNode* node = static_cast<RadonIfNode*>(base);
  int32_t ifIndex = arg1->Number();
  RETURN(lepus::Value(node->UpdateIfIndex(ifIndex)));
}

RENDERER_FUNCTION_CC(CreateForRadonNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateForRadonNode");
  CHECK_ARGC_GE(CreateForRadonNode, 2);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, CreateForRadonNode);

  uint32_t node_index = arg1->Number();
  auto* for_node = new lynx::tasm::RadonForNode(node_index);
  lepus::Value value(static_cast<RadonBase*>(for_node));
  RETURN(value);
}

RENDERER_FUNCTION_CC(CreateRadonComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonComponent");
  CHECK_ARGC_GE(CreateRadonComponent, 5);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, CreateRadonComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateRadonComponent);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, CreateRadonComponent);
  CONVERT_ARG_AND_CHECK(arg3, 3, String, CreateRadonComponent);
  CONVERT_ARG_AND_CHECK(arg4, 4, Number, CreateRadonComponent);

  uint32_t index = arg4->Number();

  int tid = static_cast<int>(arg0->Number());

  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  lepus::Context* context = LEPUS_CONTEXT();
#ifdef BUILD_LEPUS
  ComponentMould* cm = nullptr;
  CSSFragment* style_sheet = nullptr;
#else
  auto cm_it = self->component_moulds(context).find(tid);
  DCHECK(cm_it != self->component_moulds(context).end());
  ComponentMould* cm = cm_it->second.get();
#endif
  auto* page_proxy = self->page_proxy();
  auto component = new RadonComponent(page_proxy, tid, nullptr,
                                      self->style_sheet_manager(context), cm,
                                      LEPUS_CONTEXT(), index);

  component->SetName(arg2->String());
  component->SetPath(arg3->String());
  if (self->GetPageDSL() == PackageInstanceDSL::REACT) {
    component->SetDSL(PackageInstanceDSL::REACT);
    component->SetGetDerivedStateFromErrorProcessor(
        self->GetComponentProcessorWithName(component->path().c_str(),
                                            REACT_ERROR_PROCESS_LIFECYCLE,
                                            context->name()));
  }
  UpdateComponentConfig(self, component);

  component->SetGetDerivedStateFromPropsProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_PRE_PROCESS_LIFECYCLE,
                                          context->name()));

  component->SetShouldComponentUpdateProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_SHOULD_COMPONENT_UPDATE,
                                          context->name()));
  auto* base = static_cast<RadonBase*>(component);
  RETURN(lepus::Value(base));
}

RENDERER_FUNCTION_CC(CreateRadonDynamicComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonDynamicComponent");
  CHECK_ARGC_GE(CreateRadonDynamicComponent, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, CreateRadonDynamicComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateRadonDynamicComponent);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, CreateRadonDynamicComponent);
  CONVERT_ARG_AND_CHECK(arg3, 3, Number, CreateRadonDynamicComponent);

  int tid = static_cast<int>(arg0->Number());
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());
  auto entry_name = arg2->String();
  uint32_t index = arg3->Number();
  lepus::Context* context = LEPUS_CONTEXT();
  const auto& url = self->GetTargetUrl(context->name(), entry_name->str());

  RadonDynamicComponent* dynamic_component =
      RadonDynamicComponent::CreateRadonDynamicComponent(self, url, entry_name,
                                                         tid, index);
  UpdateComponentConfig(self, dynamic_component);
  auto* base = static_cast<RadonBase*>(dynamic_component);
  RETURN(lepus::Value(base));
}

RENDERER_FUNCTION_CC(CreateRadonComponentByName) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonComponentByName");
  CHECK_ARGC_GE(CreateRadonComponentByName, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, CreateRadonComponentByName);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateRadonComponentByName);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, CreateRadonComponentByName);

  uint32_t index = arg2->Number();
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg1->CPoint());

  const std::string& name = arg0->String().Get()->str();
  lepus::Context* context = LEPUS_CONTEXT();

  auto iter = self->component_name_to_id(context).find(name);
  if (iter == self->component_name_to_id(context).end()) {
    auto cm_it = self->component_moulds(name).find(0);
    ComponentMould* cm = cm_it->second.get();
    auto* page_proxy = self->page_proxy();

    auto dynamic_component = new RadonDynamicComponent(
        self, "", page_proxy, 0, nullptr, self->style_sheet_manager(name), cm,
        context, index, self->GetGlobalProps());
    dynamic_component->SetName(name);
    dynamic_component->SetPath(lepus::StringImpl::Create(cm->path()));
    UpdateComponentConfig(self, dynamic_component);
    RETURN(lepus::Value(dynamic_component));
  }

  int tid = iter->second;
  auto cm_it = self->component_moulds(tasm::DEFAULT_ENTRY_NAME).find(tid);
  DCHECK(cm_it != self->component_moulds(tasm::DEFAULT_ENTRY_NAME).end());
  ComponentMould* cm = cm_it->second.get();
  auto page_proxy = self->page_proxy();

  auto component = new RadonComponent(
      page_proxy, tid, nullptr,
      self->style_sheet_manager(tasm::DEFAULT_ENTRY_NAME), cm, context, index);

  component->SetName(name);
  component->SetPath(lepus::StringImpl::Create(cm->path()));
  component->SetDSL(self->GetPageDSL());
  if (self->GetPageDSL() == PackageInstanceDSL::REACT) {
    component->SetGetDerivedStateFromPropsProcessor(
        self->GetComponentProcessorWithName(component->path().c_str(),
                                            REACT_PRE_PROCESS_LIFECYCLE,
                                            context->name()));
    component->SetGetDerivedStateFromErrorProcessor(
        self->GetComponentProcessorWithName(component->path().c_str(),
                                            REACT_ERROR_PROCESS_LIFECYCLE,
                                            context->name()));
  }
  component->SetShouldComponentUpdateProcessor(
      self->GetComponentProcessorWithName(component->path().c_str(),
                                          REACT_SHOULD_COMPONENT_UPDATE,
                                          context->name()));
  UpdateComponentConfig(self, component);
  auto* base = static_cast<RadonBase*>(component);
  RETURN(lepus::Value(base));
}

RENDERER_FUNCTION_CC(CreateRadonPlug) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateRadonPlug");
  CHECK_ARGC_GE(CreateRadonPlug, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, CreateRadonPlug);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, CreateRadonPlug);

  lynx::base::scoped_refptr<lepus::StringImpl> tag_name = arg0->String();
  auto* base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  if (!base->IsRadonComponent()) {
    RETURN_UNDEFINED();
  }
  auto* component = static_cast<RadonComponent*>(base);
  RadonPlug* plug = new RadonPlug(tag_name, component);
  lepus::Value value(static_cast<RadonBase*>(plug));
  RETURN(value);
}

RENDERER_FUNCTION_CC(SetRadonId) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonId");
  CHECK_ARGC_EQ(SetRadonId, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonId);
  CONVERT_ARG(arg1, 1);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  auto id = arg1->String();
  if (!id->empty()) {
    node->SetIdSelector(id);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(UpdateRadonId) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateRadonId");
  CHECK_ARGC_EQ(UpdateRadonId, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateRadonId);
  CONVERT_ARG(arg1, 1);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  auto id = arg1->String();
  if (!id->empty()) {
    node->UpdateIdSelector(id);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(UpdateRadonDataSet) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateRadonDataSet");
  CHECK_ARGC_EQ(UpdateRadonDataSet, 3);

  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateRadonDataSet);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, UpdateRadonDataSet);
  CONVERT_ARG(arg2, 2);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);

  auto key = arg1->String();
  auto value = CONVERT(arg2);

  if (!key->empty()) {
    node->UpdateDataSet(key, value);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(UpdateForNodeItemCount) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateForNodeItemCount");
  CHECK_ARGC_GE(UpdateForNodeItemCount, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateForNodeItemCount);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, UpdateForNodeItemCount);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* node = static_cast<RadonForNode*>(base);
  uint32_t count = arg1->Number();
  node->UpdateChildrenCount(count);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AddRadonPlugToComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AddRadonPlugToComponent");
  CHECK_ARGC_GE(AddRadonPlugToComponent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AddRadonPlugToComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, AddRadonPlugToComponent);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* component = static_cast<RadonComponent*>(base);
  base = reinterpret_cast<RadonBase*>(arg1->CPoint());
  auto* plug = static_cast<RadonPlug*>(base);
  component->AddRadonPlug(plug->plug_name(), std::unique_ptr<RadonBase>{plug});
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(GetForNodeChildWithIndex) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "GetForNodeChildWithIndex");
  CHECK_ARGC_GE(GetForNodeChildWithIndex, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, AddRadonPlugToComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AddRadonPlugToComponent);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* node = static_cast<RadonForNode*>(base);
  uint32_t index = arg1->Number();
  RETURN(lepus::Value(node->GetForNodeChild(index)));
}

RENDERER_FUNCTION_CC(SetRadonClassTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonClassTo");
  CHECK_ARGC_GE(SetRadonClassTo, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonClassTo);
  CONVERT_ARG(arg1, 1);

  if (!arg1->IsString()) {
    RETURN_UNDEFINED();
  }

  auto clazz = arg1->String();
  if (clazz->empty()) RETURN_UNDEFINED();

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  node->UpdateClass(clazz);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetRadonStaticClassTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonStaticClassTo");
  CHECK_ARGC_GE(SetRadonStaticClassTo, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonStaticClassTo);
  CONVERT_ARG(arg1, 1);

  if (!arg1->IsString()) {
    RETURN_UNDEFINED();
  }

  auto clazz = arg1->String();
  if (clazz->empty()) RETURN_UNDEFINED();

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  node->UpdateClass(clazz);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetRadonAttributeTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonAttributeTo");
  CHECK_ARGC_EQ(SetRadonAttributeTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonAttributeTo);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, SetRadonAttributeTo);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  auto key = arg1->String();
  CONVERT_ARG(value, 2);

  node->UpdateDynamicAttribute(key, CONVERT(value));
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetRadonStaticStyleTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonStaticStyleTo");
  CHECK_ARGC_EQ(SetRadonStaticStyleTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonStaticStyleTo);
  CONVERT_ARG(arg1, 1);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, SetRadonStaticStyleTo);

  DCHECK(arg1->IsString() || arg1->IsNumber());
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  CSSPropertyID id;
  if (arg1->IsString()) {
    auto key = arg1->String();
    id = CSSProperty::GetPropertyID(key);
  } else {
    id = static_cast<CSSPropertyID>(static_cast<int>(arg1->Number()));
  }

  auto value = arg2->String();
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  // FIXME: (liujilong.me) different behavior with VirtualNode.
  if (CSSProperty::IsPropertyValid(id) && !value->empty()) {
    node->SetStaticInlineStyle(id, value,
                               tasm->GetPageConfig()->GetCSSParserConfigs());
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetRadonStaticStyleToByFiber) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonStaticStyleToByFiber");
  CHECK_ARGC_EQ(SetRadonStaticStyleToByFiber, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonStaticStyleToByFiber);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, SetRadonStaticStyleToByFiber);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, SetRadonStaticStyleToByFiber);
  CONVERT_ARG(arg3, 3);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  CSSPropertyID id =
      static_cast<CSSPropertyID>(static_cast<int>(arg1->Number()));

  if (CSSProperty::IsPropertyValid(id)) {
    CSSValuePattern pattern =
        static_cast<CSSValuePattern>(static_cast<int>(arg2->Number()));
    auto value = CONVERT(arg3);
    node->SetStaticInlineStyle(id, tasm::CSSValue(value, pattern));
  } else {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "Radon unknown css id: " + std::to_string(id));
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetRadonStyleTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonStyleTo");
  CHECK_ARGC_EQ(SetRadonStyleTo, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonStyleTo);
  CONVERT_ARG(arg1, 1);
  CONVERT_ARG(arg2, 2);
  DCHECK(arg1->IsString() || arg1->IsNumber());

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  CSSPropertyID id;
  if (arg1->IsString()) {
    auto key = arg1->String();
    id = CSSProperty::GetPropertyID(key);
  } else {
    id = static_cast<CSSPropertyID>(static_cast<int>(arg1->Number()));
  }
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  auto value = arg2->String();
  if (CSSProperty::IsPropertyValid(id) && !value->empty()) {
    auto css_values = UnitHandler::Process(
        id, CONVERT(arg2), tasm->GetPageConfig()->GetCSSParserConfigs());
    for (auto& pair : css_values) {
      node->UpdateInlineStyle(pair.first, pair.second);
    }
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetRadonDynamicStyleTo) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetRadonDynamicStyleTo");
  CHECK_ARGC_EQ(SetRadonDynamicStyleTo, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetRadonDynamicStyleTo);
  CONVERT_ARG(arg1, 1);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  if (!base->IsRadonNode()) {
    RETURN_UNDEFINED();
  }

  auto* node = static_cast<RadonNode*>(base);
  node->SetDynamicInlineStyles();
  auto style_value = arg1->String();
  auto splits = base::SplitStringByCharsOrderly(style_value->str(), {':', ';'});
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  for (size_t i = 0; i + 1 < splits.size(); i = i + 2) {
    std::string key = base::TrimString(splits[i]);
    std::string value = base::TrimString(splits[i + 1]);

    CSSPropertyID id = CSSProperty::GetPropertyID(key);
    if (CSSProperty::IsPropertyValid(id) && value.length() > 0) {
      // TODO(liyanbo):support radon cssvalue.
      auto css_values = UnitHandler::Process(
          id, lepus::Value(lepus::StringImpl::Create(value)),
          tasm->GetPageConfig()->GetCSSParserConfigs());
      for (auto& pair : css_values) {
        node->UpdateInlineStyle(pair.first, pair.second);
      }
    }
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(CreateListRadonNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateListRadonNode");
  CHECK_ARGC_EQ(CreateListRadonNode, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, CreateListRadonNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, CreateListRadonNode);

  uint32_t index = arg1->Number();
  auto* tasm = static_cast<TemplateAssembler*>(arg0->CPoint());
  auto page_proxy = tasm->page_proxy();
  auto* list = new RadonListNode(LEPUS_CONTEXT(), page_proxy, tasm, index);
  RETURN(lepus::Value(static_cast<RadonBase*>(list)));
}

RENDERER_FUNCTION_CC(DidUpdateRadonList) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DidUpdateRadonList");
  CHECK_ARGC_EQ(DidUpdateRadonList, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, DidUpdateRadonList);

  auto* list_node =
      static_cast<RadonListNode*>(reinterpret_cast<RadonBase*>(arg0->CPoint()));
  list_node->DidUpdateInLepus();
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(RegisterDataProcessor) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RegisterDataProcessor");
  DCHECK(ARGC() >= 2);
  DCHECK(ARGC() <= 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, RegisterDataProcessor);
  CONVERT_ARG_AND_CHECK(arg1, 1, Callable, RegisterDataProcessor);

  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg0->CPoint());
  if (ARGC() == 2) {
    // Default preprocessor
    self->SetDefaultProcessor(*arg1);
  } else if (ARGC() == 3) {
    CONVERT_ARG_AND_CHECK(arg2, 2, String, RegisterDataProcessor);
    std::string name = arg2->String()->str();
    self->SetProcessorWithName(*arg1, name);
  } else if (ARGC() == 4) {  // component 'getDerived'
    CONVERT_ARG_AND_CHECK(arg2, 2, String, RegisterDataProcessor);
    CONVERT_ARG_AND_CHECK(arg3, 3, String, RegisterDataProcessor);
    std::string name = arg2->String()->str();
    std::string component_path = arg3->String()->str();
    self->SetComponentProcessorWithName(*arg1, name, component_path,
                                        LEPUS_CONTEXT()->name());
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AddEventListener) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AddEventListener");
  DCHECK(ARGC() == 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, RegisterDataProcessor);
  CONVERT_ARG_AND_CHECK(arg1, 1, Callable, RegisterDataProcessor);
  TemplateAssembler* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  std::string name = arg0->String()->str();
  tasm->SetLepusEventListener(name, *arg1);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(ReFlushPage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ReFlushPage)");
  TemplateAssembler* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  tasm->ReFlushPage();
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetComponent");
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, SetComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, SetComponent);

  auto* node =
      static_cast<RadonNode*>(reinterpret_cast<RadonBase*>(arg0->CPoint()));
  auto* component = static_cast<RadonComponent*>(
      reinterpret_cast<RadonBase*>(arg1->CPoint()));

  if (node != nullptr && component != nullptr) {
    node->SetComponent(component);
  }

  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(RegisterElementWorklet) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RegisterElementWorklet");

  if (LEPUS_CONTEXT()->IsLepusContext()) {
    LOGI("RegisterElementWorklet failed since context is lepus context.");
    RETURN_UNDEFINED();
  }

  // parameter size = 3
  // [0]  worklet Instance -> JSValue
  // [1]  worklet Module Name -> String
  // [2]  component Reference -> CPointer

  DCHECK(ARGC() >= 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, RegisterElementWorklet);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, RegisterElementWorklet);
  CONVERT_ARG_AND_CHECK(arg2, 2, CPointer, RegisterElementWorklet);

  auto* base = reinterpret_cast<RadonBase*>(arg2->CPoint());
  auto* component = static_cast<RadonComponent*>(base);

  std::string worklet_name = arg1->String()->str();

  component->InsertWorklet(worklet_name, *arg0);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(RenderRadonComponentInLepus) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RenderRadonComponentInLepus");
  // TODO: Radon 异常处理.
  DCHECK(ARGC() == 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, RenderRadonComponentInLepus);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* component = static_cast<RadonComponent*>(base);
  if (component) {
    component->CreateComponentInLepus();
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(UpdateRadonComponentInLepus) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateRadonComponentInLepus");
  // TODO: Radon 异常处理.
  DCHECK(ARGC() == 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateRadonComponentInLepus);
  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* component = static_cast<RadonComponent*>(base);
  component->UpdateRadonComponentWithoutDispatch(
      BaseComponent::RenderType::UpdateByParentComponent, lepus::Value(),
      lepus::Value());
  component->UpdateComponentInLepus();
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(UpdateRadonDynamicComponentInLepus) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "UpdateRadonDynamicComponentInLepus");
  CHECK_ARGC_GE(UpdateRadonDynamicComponentInLepus, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, UpdateRadonDynamicComponentInLepus);
  CONVERT_ARG_AND_CHECK(arg1, 1, CPointer, UpdateRadonDynamicComponentInLepus);

  auto* base = reinterpret_cast<RadonBase*>(arg0->CPoint());
  auto* dynamic_component = static_cast<RadonDynamicComponent*>(base);
  if (!dynamic_component->IsEmpty()) {
    dynamic_component->UpdateRadonComponentWithoutDispatch(
        BaseComponent::RenderType::UpdateByParentComponent, lepus::Value(),
        lepus::Value());
    dynamic_component->UpdateComponentInLepus();
  }
  RETURN_UNDEFINED()
}

RENDERER_FUNCTION_CC(CreateVirtualListNode) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CreateVirtualListNode");
  CHECK_ARGC_EQ(CreateVirtualListNode, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, CreateVirtualListNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, CreateVirtualListNode);
  TemplateAssembler* self =
      reinterpret_cast<TemplateAssembler*>(arg0->CPoint());
  lepus::Context* context = LEPUS_CONTEXT();
  uint32_t eid = static_cast<uint32_t>(arg1->Number());
  auto page_proxy = self->page_proxy();
  if (self->page_proxy()->GetListNewArchitecture()) {
    auto* list = new RadonDiffListNode2(context, page_proxy, self, eid);
    lepus::Value value(static_cast<RadonBase*>(list));
    RETURN(value);
  } else {
    auto* list = new RadonDiffListNode(context, page_proxy, self, eid);
    lepus::Value value(static_cast<RadonBase*>(list));
    RETURN(value);
  }
  RETURN_UNDEFINED();
}

lepus::Value RendererFunctions::InnerTranslateResourceForTheme(
    lepus::Context* ctx, lepus::Value* argv, int argc, const char* keyIn) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "InnerTranslateResourceForTheme");
  const long params_size = argc;
  int res_start_index = 0;
  DCHECK(argc >= 1);
  if (argv->IsCPointer()) {
    DCHECK(argc >= 2);
    // ignore first cpointer param for TemplateAssembler
    res_start_index = 1;
  }
  TemplateAssembler* self = LEPUS_CONTEXT()->GetTasmPointer();
  CONVERT_ARG(res_id, res_start_index);
  std::string ret = "";
  if (self && res_id->IsString()) {
    auto res_id_str = CONVERT(res_id).String();
    if (res_id_str && !res_id_str->str().empty()) {
      int param_start_index = res_start_index + 1;
      std::string key;
      if (keyIn && *keyIn) {
        key = keyIn;
      } else if (params_size > param_start_index) {
        ++param_start_index;
        CONVERT_ARG(theme_key, (res_start_index + 1));
        if (theme_key->IsString()) {
          key = theme_key->String()->str();
        }
      }
      ret = self->TranslateResourceForTheme(res_id_str->str(), key);
      if (param_start_index < params_size && !ret.empty()) {
        InnerThemeReplaceParams(ctx, ret, argv, argc, param_start_index);
      }
    }
  }
  return lepus::Value(lepus::StringImpl::Create(ret.c_str()));
}

void RendererFunctions::InnerThemeReplaceParams(lepus::Context* ctx,
                                                std::string& retStr,
                                                lepus::Value* argv, int argc,
                                                int paramStartIndex) {
  const int params_size = argc;
  int startPos = 0;
  do {
    const char* head = retStr.c_str();
    const char* start = strchr(head + startPos, '{');
    if (start == nullptr) break;
    const char* cur = start + 1;
    int index = 0;
    while (*cur >= '0' && *cur <= '9') {
      index = index * 10 + (*cur - '0');
      ++cur;
    }
    if (*cur != '}' || index < 0 || index >= params_size - paramStartIndex) {
      startPos = static_cast<int>(cur + 1 - head);
      continue;
    }

    CONVERT_ARG(param, paramStartIndex + index);
    std::ostringstream s;
    CONVERT(param).PrintValue(s, true);
    std::string lepusStr = s.str();
    const std::string newStr = retStr.substr(0, start - head) + lepusStr;
    startPos = static_cast<int>(newStr.size());
    const int endPos = static_cast<int>(cur + 1 - head);
    retStr = newStr + retStr.substr(endPos, retStr.size() - endPos);
  } while (static_cast<size_t>(startPos) < retStr.size());
}

RENDERER_FUNCTION_CC(ThemedTranslation) {
  lepus::Value val = RendererFunctions::InnerTranslateResourceForTheme(
      ctx, argv, argc, nullptr);
  RETURN(val);
}

RENDERER_FUNCTION_CC(ThemedTranslationLegacy) {
  // FIXME: this function if to solve old version lynx had some mistaken when
  // register _sysTheme and _GetLazyLoadCount, if remove this function some
  // template compile with old version cli may not be able to use the theme
  // function
  // clang-format on
  CHECK_ARGC_GE(GetLazyLoadCount, 2);
  CONVERT_ARG(arg1, 1);
  if (arg1->IsString()) {
    return ThemedTranslation(ctx, argv, argc);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(ThemedLanguageTranslation) {
  lepus::Value val =
      InnerTranslateResourceForTheme(ctx, argv, argc, "language");
  RETURN(lepus::Value(val));
}

RENDERER_FUNCTION_CC(I18nResourceTranslation) {
  CHECK_ARGC_EQ(I18nResourceTranslation, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, I18nResourceTranslation);
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  lepus::Value locale = arg0->GetProperty("locale");
  lepus::Value channel = arg0->GetProperty("channel");
  lepus::Value fallback_url = arg0->GetProperty("fallback_url");
  RETURN(self->GetI18nResources(locale, channel, fallback_url));
}

RENDERER_FUNCTION_CC(GetGlobalProps) {
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto global_props = self->GetGlobalProps();
  RETURN(global_props);
}

RENDERER_FUNCTION_CC(GetSystemInfo) {
  RETURN(GetSystemInfoFromTasm(LEPUS_CONTEXT()->GetTasmPointer()));
}

RENDERER_FUNCTION_CC(HandleExceptionInLepus) {
  CHECK_ARGC_EQ(HandleExceptionInLepus, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, HandleExceptionInLepus);
  CONVERT_ARG_AND_CHECK(arg1, 1, Object, HandleExceptionInLepus);
  lepus::Value msg = arg1->GetProperty("message");
  LOGE("HandleExceptionInLepus: " << msg);
  auto* component = reinterpret_cast<RadonComponent*>(arg0->CPoint());
  auto* errorComponent =
      static_cast<RadonComponent*>(component->GetErrorBoundary());
  if (errorComponent != nullptr) {
    errorComponent->SetRenderError(*arg1);
  }
  RETURN_UNDEFINED();
}

// attach optimize information for i18n resource
RENDERER_FUNCTION_CC(FilterI18nResource) {
  CHECK_ARGC_EQ(FilterI18nResource, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, FilterI18nResource);
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  lepus::Value channel = arg0->GetProperty("channel");
  lepus::Value locale = arg0->GetProperty("locale");
  lepus::Value reserve_keys = arg0->GetProperty("reserveKeys");
  self->FilterI18nResource(channel, locale, reserve_keys);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(MarkPageElement) {
  CHECK_ARGC_EQ(MarkPageElement, 0);
  LOGI("MarkPageElement");
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  self->page_proxy()->SetPageElementEnabled(true);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SendGlobalEvent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SendGlobalEvent");
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  CHECK_ARGC_EQ(SendGlobalEvent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, SendGlobalEvent);
  lepus::Value* arg1 = argv + 1;
  tasm->SendGlobalEvent(arg0->String()->str(), *arg1);
  RETURN_UNDEFINED();
}

/* Element API BEGIN */
RENDERER_FUNCTION_CC(FiberCreateElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateElement");
  // parameter size >= 2
  // [0] String -> element's tag
  // [1] Number -> parent component/page's unique id
  // [2] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, FiberCreateElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, FiberCreateElement);

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();
  auto element = manager->CreateFiberNode(arg0->String());
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg1->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreatePage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreatePage");

  // notify devtool page is updated.
  EXEC_EXPR_FOR_INSPECTOR(LEPUS_CONTEXT()
                              ->GetTasmPointer()
                              ->page_proxy()
                              ->element_manager()
                              ->OnDocumentUpdated());

  // parameter size >= 2
  // [0] String -> componentID
  // [1] Number -> component/page's css fragment id
  // [2] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreatePage, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, FiberCreatePage);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, FiberCreatePage);

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  auto page = manager->CreateFiberPage(arg0->String(),
                                       static_cast<int32_t>(arg1->Number()));
  page->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(page->impl_id()));
  page->set_style_sheet_manager(
      self->style_sheet_manager(tasm::DEFAULT_ENTRY_NAME));

  ON_NODE_CREATE(page);
  ON_NODE_ADDED(page);
  RETURN(lepus::Value(page));
}

RENDERER_FUNCTION_CC(FiberCreateComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateComponent");
  // parameter size >= 6
  // [0] Number -> parent component/page's unique id
  // [1] String -> self's componentID
  // [2] Number -> component/page's css fragment id
  // [3] String -> entry name
  // [4] String -> component name
  // [5] String -> component path
  // [6] Object -> component config, not used now
  // [7] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateComponent, 6);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberCreateComponent);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, FiberCreateComponent);
  CONVERT_ARG_AND_CHECK(arg3, 3, String, FiberCreateComponent);
  CONVERT_ARG_AND_CHECK(arg4, 4, String, FiberCreateComponent);
  CONVERT_ARG_AND_CHECK(arg5, 5, String, FiberCreateComponent);
  CONVERT_ARG(arg6, 6);

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  const auto& parent_component_unique_id = static_cast<int64_t>(arg0->Number());
  const auto& component_id = arg1->String();
  const auto& css_id = static_cast<int32_t>(arg2->Number());
  const auto& entry_name = arg3->String();
  const auto& name = arg4->String();
  const auto& path = arg5->String();

  const std::string& entry_name_str =
      entry_name->str().empty() ? tasm::DEFAULT_ENTRY_NAME : entry_name->str();

  auto component_element = manager->CreateFiberComponent(
      component_id, css_id, lepus::String(entry_name_str.c_str()), name, path);
  component_element->SetParentComponentUniqueIdForFiber(
      parent_component_unique_id);
  component_element->set_style_sheet_manager(
      self->style_sheet_manager(entry_name_str));
  component_element->SetConfig(*arg6);

  ON_NODE_CREATE(component_element);
  RETURN(lepus::Value(component_element));
}

RENDERER_FUNCTION_CC(FiberCreateView) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateView");
  // parameter size >= 1
  // [0] Number -> parent component/page's unique id
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateView, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateView);

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  auto element = manager->CreateFiberView();
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg0->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateList) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateList");
  // parameter size >= 3
  // [0] Number -> parent component/page's unique id
  // [1] Function -> componentAtIndex callback
  // [2] Function -> enqueueComponent callback
  // [3] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateList, 3);
  CONVERT_ARG_AND_CHECK(parent_component_unique_id, 0, Number, FiberCreateList);
  CONVERT_ARG(component_at_index, 1);
  CONVERT_ARG(enqueue_component, 2);

  constexpr const static char* kTag = "tag";
  constexpr const static char* kDefaultTag = "list";

  lepus::String tag = kDefaultTag;
  if (argc > 3) {
    CONVERT_ARG(arg3, 3);
    const auto& custom_tag = arg3->GetProperty(kTag);
    if (custom_tag.IsString()) {
      tag = custom_tag.String();
    }
  }

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  auto element = manager->CreateFiberList(self, tag, *component_at_index,
                                          *enqueue_component);
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(parent_component_unique_id->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateScrollView) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateScrollView");
  // parameter size >= 1
  // [0] Number -> parent component/page's unique id
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateScrollView, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateScrollView);

  constexpr const static char* kTag = "tag";
  constexpr const static char* kDefaultTag = "scroll-view";

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  lepus::String tag = kDefaultTag;
  if (argc > 1) {
    CONVERT_ARG(arg1, 1);
    const auto& custom_tag = arg1->GetProperty(kTag);
    if (custom_tag.IsString()) {
      tag = custom_tag.String();
    }
  }
  auto element = manager->CreateFiberScrollView(tag);

  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg0->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateText) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateText");
  // parameter size >= 1
  // [0] Number -> parent component/page's unique id
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateText, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateText);
  constexpr const static char* kTag = "tag";
  constexpr const static char* kDefaultTag = "text";

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  lepus::String tag = kDefaultTag;
  if (argc > 1) {
    CONVERT_ARG(arg1, 1);
    const auto& custom_tag = arg1->GetProperty(kTag);
    if (custom_tag.IsString()) {
      tag = custom_tag.String();
    }
  }
  auto element = manager->CreateFiberText(tag);
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg0->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateImage) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateImage");
  // parameter size >= 1
  // [0] Number -> parent component/page's unique id
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateImage, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateImage);
  constexpr const static char* kTag = "tag";
  constexpr const static char* kDefaultTag = "image";

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  lepus::String tag = kDefaultTag;
  if (argc > 1) {
    CONVERT_ARG(arg1, 1);
    const auto& custom_tag = arg1->GetProperty(kTag);
    if (custom_tag.IsString()) {
      tag = custom_tag.String();
    }
  }
  auto element = manager->CreateFiberImage(tag);
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg0->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateRawText) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateRawText");
  // parameter size >= 1
  // [0] String -> raw text's content
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateRawText, 1);
  CONVERT_ARG(content, 0);

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  auto element = manager->CreateFiberRawText();
  element->SetText(*content);

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateNonElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateNonElement");
  // parameter size >= 1
  // [0] Number -> parent component/page's unique id
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateImage, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateNonElement);

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  auto element = manager->CreateFiberNoneElement();
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg0->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberCreateWrapperElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberCreateWrapperElement");
  // parameter size >= 1
  // [0] Number -> parent component/page's unique id
  // [1] Object|Undefined -> optional info, not used now
  CHECK_ARGC_GE(FiberCreateImage, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, FiberCreateWrapperElement);

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  auto element = manager->CreateFiberWrapperElement();
  element->SetParentComponentUniqueIdForFiber(
      static_cast<int64_t>(arg0->Number()));

  ON_NODE_CREATE(element);
  RETURN(lepus::Value(element));
}

RENDERER_FUNCTION_CC(FiberAppendElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberAppendElement");
  // parameter size = 2
  // [0] RefCounted -> parent element
  // [1] RefCounted -> child element
  CHECK_ARGC_GE(FiberAppendElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberAppendElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, FiberAppendElement);
  auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto child = static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());
  parent->InsertNode(child);

  ON_NODE_ADDED(child);
  RETURN(lepus::Value(child));
}

RENDERER_FUNCTION_CC(FiberRemoveElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberRemoveElement");
  // parameter size = 2
  // [0] RefCounted -> parent element
  // [1] RefCounted -> child element
  CHECK_ARGC_GE(FiberRemoveElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberRemoveElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, FiberRemoveElement);
  auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto child = static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());
  parent->RemoveNode(child);

  ON_NODE_REMOVED(child);
  RETURN(lepus::Value(child));
}

RENDERER_FUNCTION_CC(FiberInsertElementBefore) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberInsertElementBefore");
  // parameter size = 3
  // [0] RefCounted -> parent element
  // [1] RefCounted -> child element
  // [2] RefCounted|Number|null|Undefined -> ref element
  CHECK_ARGC_GE(FiberInsertElementBefore, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberInsertElementBefore);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, FiberInsertElementBefore);
  CONVERT_ARG(arg2, 2)
  auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto child = static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());
  if (arg2->IsRefCounted()) {
    auto ref = static_scoped_pointer_cast<FiberElement>(arg2->RefCounted());
    parent->InsertNodeBefore(child, ref);
  } else {
    parent->InsertNode(child);
  }

  ON_NODE_ADDED(child);
  RETURN(lepus::Value(child));
}

RENDERER_FUNCTION_CC(FiberFirstElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberFirstElement");
  // parameter size = 1
  // [0] RefCounted -> parent element
  CHECK_ARGC_GE(FiberFirstElement, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  constexpr const static int32_t kFirstElementIndex = 0;

  auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto child =
      static_cast<FiberElement*>(parent->GetChildAt(kFirstElementIndex));
  if (child == nullptr) {
    RETURN_UNDEFINED();
  }

  RETURN(lepus::Value(base::scoped_refptr<FiberElement>(child)));
}

RENDERER_FUNCTION_CC(FiberLastElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberLastElement");
  // parameter size = 1
  // [0] RefCounted -> parent element
  CHECK_ARGC_GE(FiberLastElement, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  if (parent->GetChildCount() == 0) {
    RETURN_UNDEFINED();
  }
  auto child = static_cast<FiberElement*>(
      parent->GetChildAt(parent->GetChildCount() - 1));
  if (child == nullptr) {
    RETURN_UNDEFINED();
  }
  RETURN(lepus::Value(base::scoped_refptr<FiberElement>(child)));
}

RENDERER_FUNCTION_CC(FiberNextElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberNextElement");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberNextElement, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto* element =
      static_scoped_pointer_cast<FiberElement>(arg0->RefCounted()).Get();
  auto* parent = static_cast<FiberElement*>(element->parent());

  if (parent == nullptr) {
    RETURN_UNDEFINED()
  }

  FiberElement* next = static_cast<FiberElement*>(element->next_sibling());
  if (next == nullptr) {
    RETURN_UNDEFINED();
  }

  RETURN(lepus::Value(base::scoped_refptr<FiberElement>(next)));
}

RENDERER_FUNCTION_CC(FiberReplaceElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberReplaceElement");
  // parameter size = 2
  // [0] RefCounted -> new element
  // [1] RefCounted -> old element
  // [return] undefined
  CHECK_ARGC_GE(FiberReplaceElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberReplaceElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, FiberReplaceElement);

  auto new_element =
      static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto old_element =
      static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());

  // if new element == old element, return
  if (new_element->impl_id() == old_element->impl_id()) {
    LOGI("FiberReplaceElement parameters are the same, return directly.");
    RETURN_UNDEFINED();
  }

  auto* parent = static_cast<FiberElement*>(old_element->parent());
  if (parent == nullptr) {
    LOGE("FiberReplaceElement failed since parent is null.");
    RETURN_UNDEFINED();
  }

  parent->InsertNodeBefore(new_element, old_element);
  parent->RemoveNode(old_element);

  ON_NODE_ADDED(new_element);
  ON_NODE_REMOVED(old_element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberReplaceElements) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberReplaceElement");
  // parameter size = 3
  // [0] RefCounted -> parent
  // [0] RefCounted | Array | Null -> new element
  // [1] RefCounted | Array | Null -> old element
  // [return] undefined
  CHECK_ARGC_GE(FiberReplaceElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberReplaceElement);
  CONVERT_ARG(arg1, 1);
  CONVERT_ARG(arg2, 2);

  // Get parent
  auto* parent =
      static_scoped_pointer_cast<FiberElement>(arg0->RefCounted()).Get();
  if (parent == nullptr) {
    LOGE("FiberReplaceElement failed since parent is null.");
    RETURN_UNDEFINED();
  }

  // Get inserted elements.
  std::deque<base::scoped_refptr<FiberElement>> inserted_elements{};
  if (arg1->IsRefCounted()) {
    inserted_elements.emplace_back(
        static_scoped_pointer_cast<FiberElement>(arg1->RefCounted()));
  } else if (arg1->IsArrayOrJSArray()) {
    tasm::ForEachLepusValue(
        *arg1, [&inserted_elements](const auto& index, const auto& value) {
          if (value.IsRefCounted()) {
            inserted_elements.emplace_back(
                static_scoped_pointer_cast<FiberElement>(value.RefCounted()));
          }
        });
  }

  // Get removed elements.
  std::deque<base::scoped_refptr<FiberElement>> removed_elements{};
  if (arg2->IsRefCounted()) {
    removed_elements.emplace_back(
        static_scoped_pointer_cast<FiberElement>(arg2->RefCounted()));
  } else if (arg2->IsArrayOrJSArray()) {
    tasm::ForEachLepusValue(*arg2, [&removed_elements](const auto& index,
                                                       const auto& value) {
      if (value.IsRefCounted()) {
        removed_elements.emplace_back(
            static_scoped_pointer_cast<FiberElement>(value.RefCounted()).Get());
      }
    });
  }

  // Perform a simple diff on the inserted_elements and removed_elements,
  // removing each element one by one until either inserted_elements
  // orremoved_elements are empty or the elements are not the same. Same applies
  // to the tail end.
  while (!inserted_elements.empty() && !removed_elements.empty() &&
         inserted_elements.front()->impl_id() ==
             removed_elements.front()->impl_id()) {
    inserted_elements.pop_front();
    removed_elements.pop_front();
  }
  while (!inserted_elements.empty() && !removed_elements.empty() &&
         inserted_elements.back()->impl_id() ==
             removed_elements.back()->impl_id()) {
    inserted_elements.pop_back();
    removed_elements.pop_back();
  }

  if (inserted_elements.empty() && removed_elements.empty()) {
    RETURN_UNDEFINED();
  }

  parent->ReplaceElements(inserted_elements, removed_elements);

  EXEC_EXPR_FOR_INSPECTOR({
    for (const auto& child : inserted_elements) {
      ON_NODE_ADDED(child);
    }
    for (const auto& child : removed_elements) {
      ON_NODE_REMOVED(child);
    }
  });
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberSwapElement) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSwapElement");
  // parameter size = 2
  // [0] RefCounted -> left element
  // [1] RefCounted -> right element
  // [return] undefined
  CHECK_ARGC_GE(FiberSwapElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSwapElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, FiberSwapElement);

  auto left_element =
      static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto right_element =
      static_scoped_pointer_cast<FiberElement>(arg1->RefCounted());

  auto* left_parent = static_cast<FiberElement*>(left_element->parent());
  if (left_parent == nullptr) {
    LOGE("FiberReplaceElement failed since left parent is null.");
    RETURN_UNDEFINED();
  }

  auto* right_parent = static_cast<FiberElement*>(right_element->parent());
  if (right_parent == nullptr) {
    LOGE("FiberReplaceElement failed since right parent is null.");
    RETURN_UNDEFINED();
  }

  auto left_index = left_parent->IndexOf(left_element.Get());
  auto right_index = right_parent->IndexOf(right_element.Get());

  left_parent->RemoveNode(left_element);
  ON_NODE_REMOVED(left_element);

  right_parent->RemoveNode(right_element);
  ON_NODE_REMOVED(right_element);

  // TODO(linxs): opt this logic.
  if (right_index < left_index) {
    right_parent->InsertNode(left_element, right_index);
    left_parent->InsertNode(right_element, left_index);
  } else {
    left_parent->InsertNode(right_element, left_index);
    right_parent->InsertNode(left_element, right_index);
  }

  ON_NODE_ADDED(left_element);
  ON_NODE_ADDED(right_element);
  RETURN_UNDEFINED();
}

// This function accepts only one parameter, the 0th is the element. The return
// value is the element's parent.
RENDERER_FUNCTION_CC(FiberGetParent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetParent");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetParent, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto child = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto parent = static_cast<FiberElement*>(child->parent());
  if (parent == nullptr) {
    RETURN_UNDEFINED();
  }

  RETURN(lepus::Value(base::scoped_refptr<FiberElement>(parent)));
}

RENDERER_FUNCTION_CC(FiberGetChildren) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetChildren");
  // parameter size = 1
  // [0] RefCounted -> parent element
  CHECK_ARGC_GE(FiberGetChildren, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto parent = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());

  auto ary = lepus::CArray::Create();
  const auto& children = parent->children();
  for (const auto& c : children) {
    ary->push_back(lepus::Value(c));
  }
  RETURN(lepus::Value(ary));
}

RENDERER_FUNCTION_CC(FiberCloneElement) {
  // TODO(linxs): impl this later
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberElementIsEqual) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElementIsEqual");
  // parameter size = 2
  // [0] RefCounted -> left element
  // [1] RefCounted -> right element
  CHECK_ARGC_GE(FiberElementIsEqual, 2);
  CONVERT_ARG(arg0, 0)
  CONVERT_ARG(arg1, 1)

  if (!arg0->RefCounted() || !arg1->RefCounted()) {
    return lepus::Value(false);
  }

  auto left =
      static_scoped_pointer_cast<FiberElement>(arg0->RefCounted()).Get();
  auto right =
      static_scoped_pointer_cast<FiberElement>(arg1->RefCounted()).Get();
  RETURN(lepus::Value(left == right));
}

RENDERER_FUNCTION_CC(FiberGetElementUniqueID) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetElementUniqueID");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetElementUniqueID, 1);
  CONVERT_ARG(arg0, 0);
  int64_t unique_id = -1;
  if (arg0->IsRefCounted()) {
    auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
    unique_id = element->impl_id();
  }
  RETURN(lepus::Value(unique_id));
}

RENDERER_FUNCTION_CC(FiberGetTag) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetTag");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetTag, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  RETURN(lepus::Value(element->GetTag().c_str()));
}

RENDERER_FUNCTION_CC(FiberSetAttribute) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetAttribute");
  // parameter size = 3
  // [0] RefCounted -> element
  // [1] String -> key
  // [2] any -> value
  CHECK_ARGC_GE(FiberSetAttribute, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetAttribute);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberSetAttribute);
  CONVERT_ARG(arg2, 2);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  element->SetAttribute(arg1->String(), *arg2);

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberGetAttributes) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetAttributes");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetAttributes, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto attr_std_map = element->data_model()->attributes();

  lepus::Value res(lepus::Dictionary::Create());
  for (const auto& pair : attr_std_map) {
    res.SetProperty(pair.first, pair.second.first);
  }

  RETURN(res);
}

RENDERER_FUNCTION_CC(FiberAddClass) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberAddClass");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] String -> class name
  CHECK_ARGC_GE(FiberAddClass, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberAddClass);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberAddClass);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  const auto& old_classes = element->classes();
  element->SetClass(arg1->String());

  element->OnClassChanged(old_classes, element->classes());
  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberSetClasses) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetClasses");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] String -> classes
  CHECK_ARGC_GE(FiberSetClasses, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetClasses);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberSetClasses);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto clazz = arg1->String();
  const auto& old_classes = element->classes();
  if (clazz->empty()) {
    element->RemoveAllClass();
    element->OnClassChanged(old_classes, {});
    ON_NODE_MODIFIED(element);
    RETURN_UNDEFINED();
  }

  element->RemoveAllClass();

  if (clazz->str().find(" ") == std::string::npos) {
    element->SetClass(clazz);
    element->OnClassChanged(old_classes, {clazz});
    ON_NODE_MODIFIED(element);
    RETURN_UNDEFINED();
  }

  std::vector<std::string> classes;
  if (!base::SplitString(clazz->str(), ' ', classes)) {
    element->OnClassChanged(old_classes, {});
    RETURN_UNDEFINED();
  }

  for (const auto& a_class : classes) {
    auto cl = base::TrimString(a_class);
    if (!cl.empty()) {
      element->SetClass(cl);
    };
  }

  element->OnClassChanged(old_classes, element->classes());
  ON_NODE_MODIFIED(element);

  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberGetClasses) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetClasses");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetClasses, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto ary = lepus::CArray::Create();
  for (const auto& c : element->classes()) {
    ary->push_back(lepus::Value(c.c_str()));
  }
  RETURN(lepus::Value(ary));
}

RENDERER_FUNCTION_CC(FiberAddInlineStyle) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberAddInlineStyle");
  // parameter size = 3
  // [0] RefCounted -> element
  // [1] Number -> css property id
  // [2] value -> style
  CHECK_ARGC_GE(FiberAddInlineStyle, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberAddInlineStyle);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, FiberAddInlineStyle);
  CONVERT_ARG(arg2, 2);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  element->SetStyle(static_cast<CSSPropertyID>(arg1->Number()), *arg2);

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberSetInlineStyles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetInlineStyles");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] String -> inline-style
  CHECK_ARGC_GE(FiberSetInlineStyles, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetInlineStyles);
  CONVERT_ARG(arg1, 1);
  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());

  // Since FiberSetInlineStyles means clear the previous value and set the new
  // value, then, call RemoveAllInlineStyles before call fiber element's
  // SetStyle.
  element->RemoveAllInlineStyles();

  // TODO(linxs): opt this function, should diff first.
  if (arg1->IsString()) {
    auto tmp_str = arg1->String();
    auto style_value = tmp_str->c_str();
    auto splits = base::SplitStringByCharsOrderly(style_value, {':', ';'});

    for (size_t i = 0; i + 1 < splits.size(); i = i + 2) {
      std::string key = base::TrimString(splits[i]);
      std::string value = base::TrimString(splits[i + 1]);
      CSSPropertyID id = CSSProperty::GetPropertyID(key);
      if (CSSProperty::IsPropertyValid(id) && value.length() > 0) {
        element->SetStyle(id, lepus::Value(value.c_str()));
      }
    }
  } else if (arg1->IsObject()) {
    tasm::ForEachLepusValue(
        *arg1, [&](const lepus::Value& key, const lepus::Value& value) {
          auto id = CSSProperty::GetPropertyID(
              base::CamelCaseToDashCase(key.String()->str()));
          if (CSSProperty::IsPropertyValid(id)) {
            element->SetStyle(id, value);
          }
        });
  } else if (!arg1->IsEmpty()) {
    // If arg1 is not string, not obejct and not empty, should crash like
    // CONVERT_ARG_AND_CHECK
    RenderFatal(false,
                "FiberSetInlineStyles: params 1 should use String or Object");
  }

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberGetInlineStyles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetInlineStyles");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetInlineStyles, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, CPointer, FiberGetInlineStyles);

  // TODO(linxs): return inline style object
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberSetParsedStyles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetParsedStyles");
  // parameter size >= 2
  // [0] RefCounted -> element
  // [1] String -> parsed styles' key
  // [2] Object | Undefined | Null -> options
  CHECK_ARGC_GE(FiberSetParsedStyles, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetParsedStyles);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberSetParsedStyles);
  CONVERT_ARG(arg2, 2);

  std::string entry_name = tasm::DEFAULT_ENTRY_NAME;
  if (arg2->IsObject()) {
    constexpr const static char* kEntryName = "entryName";
    const auto& entry_name_prop = arg2->GetProperty(kEntryName);
    if (entry_name_prop.IsString()) {
      entry_name = entry_name_prop.ToString();
    }
  }
  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  auto entry = LEPUS_CONTEXT()->GetTasmPointer()->FindTemplateEntry(entry_name);
  element->SetParsedStyle(entry->GetParsedStyles(arg1->String()->str()), *arg2);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberGetComputedStyles) {
  // TODO(songshourui.null): impl this later
  RETURN_UNDEFINED();
}

// This function accepts four parameters, the 0th is the element, the 1st is the
// event name, the 2nd is the event type, and the 3rd is the event function.
// When func is undefined, delete the corresponding event; when it is string,
// overwrite the previous name and type and add the corresponding js event; when
// it is callable, overwrite the previous name and type and add the
// corresponding lepus event.
RENDERER_FUNCTION_CC(FiberAddEvent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberAddEvent");
  // parameter size = 4
  // [0] RefCounted -> element
  // [1] String -> type
  // [2] String -> name
  // [3] String/Function -> function
  CHECK_ARGC_GE(FiberAddEvent, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberAddEvent);
  CONVERT_ARG_AND_CHECK(type, 1, String, FiberAddEvent);
  CONVERT_ARG_AND_CHECK(name, 2, String, FiberAddEvent);
  CONVERT_ARG(callback, 3);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  if (callback->IsEmpty()) {
    // If callback is undefined, remove event.
    element->RemoveEvent(name->String(), type->String());
  } else if (callback->IsString()) {
    element->SetJSEventHandler(name->String(), type->String(),
                               callback->String());
  } else if (callback->IsCallable()) {
    element->SetLepusEventHandler(name->String(), type->String(),
                                  lepus::Value(), *callback);
  } else {
    LOGW(
        "FiberAddEvent's 3rd parameter must be undefined, null, string or "
        "callable.");
  }

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

// The function accepts two parameters, the 0th is element and the 1st is Array
// composited by evnet object, which must contain three keys: name, type, and
// function. When this function is executed, the element's all events will be
// deleted first, and then the array will be traversed to add corresponding
// events.
RENDERER_FUNCTION_CC(FiberSetEvents) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetEvents");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] Array -> events : [{name, type, function}]
  CHECK_ARGC_GE(FiberSetEvents, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetEvents);
  CONVERT_ARG(callbacks, 1);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  element->RemoveAllEvents();

  if (!callbacks->IsArrayOrJSArray()) {
    ON_NODE_MODIFIED(element);
    RETURN_UNDEFINED();
  }

  ForEachLepusValue(*callbacks, [element](const lepus::Value& index,
                                          const lepus::Value& value) {
    constexpr const static char* kName = "name";
    constexpr const static char* kType = "type";
    constexpr const static char* kFunction = "function";

    const auto& name = value.GetProperty(kName);
    const auto& type = value.GetProperty(kType);
    const auto& callback = value.GetProperty(kFunction);

    if (!name.IsString()) {
      LOGW("FiberSetEvents' "
           << value.Number()
           << " parameter must contain name, and name must be string.");
      return;
    }
    if (!type.IsString()) {
      LOGW("FiberSetEvents' "
           << value.Number()
           << " parameter must contain type, and type must be string.");
      return;
    }
    if (callback.IsString()) {
      element->SetJSEventHandler(name.String(), type.String(),
                                 callback.String());
    } else if (callback.IsCallable()) {
      element->SetLepusEventHandler(name.String(), type.String(),
                                    lepus::Value(), callback);
    } else {
      LOGW("FiberSetEvents' " << value.Number()
                              << " parameter must contain callback, and "
                                 "callback must be string or callable.");
    }
  });

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

// The function takes three parameters, element, event name and event type. When
// element does not have any corresponding event binding, return lepus::Value().
// Otherwise return a event object, where event contains name, type, jsFunction,
// lepusFunction and piperEventContent. The event must contain name and type,
// and may contain only one of jsFunction, lepusFunction and piperEventContent.
RENDERER_FUNCTION_CC(FiberGetEvent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetEvent");
  // parameter size >= 3
  // [0] RefCounted -> element
  // [1] String -> event name
  // [2] String -> event type
  CHECK_ARGC_GE(FiberGetEvent, 3);
  CONVERT_ARG(arg0, 0);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberGetEvent);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, FiberGetEvent);
  constexpr const static char* kGlobalBind = "global-bindEvent";

  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  // Get element.
  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  // Get event type.
  const auto& type = arg2->String()->str();

  // Get events according to the event type.
  const auto& events = type == kGlobalBind
                           ? element->data_model()->global_bind_events()
                           : element->data_model()->static_events();

  // Return lepus::Value() if not find the event with event name.
  auto iter = events.find(arg1->String()->str());
  if (iter == events.end()) {
    RETURN_UNDEFINED();
  }
  // Return lepus::Value() if event type not the same as required type.
  if (iter->second->type().str() != type) {
    RETURN_UNDEFINED();
  }

  RETURN(iter->second->ToLepusValue());
}

// The function takes one parameter, element. When element does not have any
// event binding, return lepus::Value(). Otherwise return a
// Record<eventName:String, Array<event:Object>>, where event contains name,
// type, jsFunction, lepusFunction and piperEventContent. The event must contain
// name and type, and may contain only one of jsFunction, lepusFunction and
// piperEventContent.
RENDERER_FUNCTION_CC(FiberGetEvents) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetEvents");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetEvents, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  const auto& event = element->data_model()->static_events();
  const auto& global_event = element->data_model()->global_bind_events();

  if (event.empty() && global_event.empty()) {
    RETURN_UNDEFINED();
  }

  const static auto& merge_event = [](const EventMap& event,
                                      lepus::Value& result) {
    for (const auto& e : event) {
      lynx::base::scoped_refptr<lepus::CArray> ary;
      if (result.Contains(e.first)) {
        ary = result.GetProperty(e.first).Array();
      } else {
        ary = lepus::CArray::Create();
        result.SetProperty(e.first, lepus::Value(ary));
      }
      ary->push_back(e.second->ToLepusValue());
    }
  };
  lepus::Value result = lepus::Value(lepus::Dictionary::Create());

  merge_event(event, result);
  merge_event(global_event, result);

  RETURN(result);
}

RENDERER_FUNCTION_CC(FiberSetID) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetID");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] String|undefined -> id
  CHECK_ARGC_GE(FiberSetID, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetID);
  CONVERT_ARG(arg1, 1);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  if (arg1->IsString()) {
    element->SetIdSelector(arg1->String());
  } else {
    constexpr const static char* kEmptyIdSelector = "";
    element->SetIdSelector(kEmptyIdSelector);
  }

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberGetID) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetID");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetID, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  RETURN(lepus::Value(element->GetIdSelector().c_str()));
}

RENDERER_FUNCTION_CC(FiberAddDataset) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberAddDataset");
  // parameter size = 3
  // [0] RefCounted -> element
  // [1] String -> key
  // [2] any -> value
  CHECK_ARGC_GE(FiberAddDataset, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberAddDataset);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberAddDataset);
  CONVERT_ARG(arg2, 2);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  element->AddDataset(arg1->String(), *arg2);

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberSetDataset) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetDataset");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] any -> dataset
  CHECK_ARGC_GE(FiberSetDataset, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberSetDataset);
  CONVERT_ARG(arg1, 1);

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  element->SetDataset(*arg1);

  ON_NODE_MODIFIED(element);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberGetDataset) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetDataset");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_GE(FiberGetDataset, 1);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  const auto& data_map = element->dataset();
  auto dict = lepus::Dictionary::Create();
  for (const auto& pair : data_map) {
    dict->set(pair.first.c_str(), pair.second);
  }
  RETURN(lepus::Value(dict));
}

RENDERER_FUNCTION_CC(FiberGetDataByKey) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetDataByKey");
  // parameter size = 2
  // [0] RefCounted -> element
  // [1] String -> key
  CHECK_ARGC_GE(FiberGetDataByKey, 2);
  CONVERT_ARG(arg0, 0);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberGetDataByKey);

  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }

  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  const auto& data_map = element->dataset();

  auto iter = data_map.find(arg1->String());
  if (iter == data_map.end()) {
    RETURN_UNDEFINED();
  }

  RETURN(lepus::Value(iter->second));
}

RENDERER_FUNCTION_CC(FiberGetComponentID) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberGetComponentID");
  // parameter size = 1
  // [0] RefCounted -> component element
  CHECK_ARGC_GE(FiberGetComponentID, 1);
  CONVERT_ARG(arg0, 0);

  // If arg0 is not RefCounted, return lepus::Value()
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED()
  }

  // If element is not component, return lepus::Value()
  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  if (!element->is_component()) {
    RETURN_UNDEFINED()
  }

  auto component =
      static_scoped_pointer_cast<ComponentElement>(arg0->RefCounted());
  RETURN(lepus::Value(component->component_id().c_str()));
}

RENDERER_FUNCTION_CC(FiberUpdateComponentID) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberUpdateComponentID");
  // parameter size = 2
  // [0] RefCounted -> component element
  // [1] String -> component id
  CHECK_ARGC_GE(FiberUpdateComponentID, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberUpdateComponentID);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberUpdateComponentID);

  auto component =
      static_scoped_pointer_cast<ComponentElement>(arg0->RefCounted());
  component->set_component_id(arg1->String());
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberUpdateListCallbacks) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberUpdateListCallbacks");
  // parameter size = 3
  // [0] RefCounted -> list element
  // [1] Function -> component_at_index callback
  // [2] Function -> enqueue_component callback
  CHECK_ARGC_GE(FiberUpdateListCallbacks, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, FiberUpdateListCallbacks);
  CONVERT_ARG(arg1, 1);
  CONVERT_ARG(arg2, 2);
  auto list_element =
      static_scoped_pointer_cast<ListElement>(arg0->RefCounted());
  list_element->UpdateCallbacks(*arg1, *arg2);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberSetCSSId) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetCSSId");
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  // parameter size = 2
  // [0] RefCounted|Array<RefCounted> -> element(s)
  // [1] Number -> css_id
  // [2] String|Undefined -> optional, entry_name

  CHECK_ARGC_GE(FiberSetCSSId, 2);
  CONVERT_ARG(arg0, 0);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, FiberSetCSSId);
  std::string entry_name = tasm::DEFAULT_ENTRY_NAME;
  if (argc > 2) {
    CONVERT_ARG_AND_CHECK(arg2, 2, String, FiberSetCSSId);
    entry_name = arg2->String()->str();
  }

  std::shared_ptr<CSSStyleSheetManager> style_sheet_manager =
      self->style_sheet_manager(entry_name);

  auto looper = [style_sheet_manager, arg1](const lepus::Value& key,
                                            const lepus::Value& value) {
    RenderFatal(value.IsRefCounted(),
                "FiberSetCSSId params 0 type should use RefCounted or "
                "array of RefCounted");
    auto element = static_scoped_pointer_cast<FiberElement>(value.RefCounted());
    element->set_style_sheet_manager(style_sheet_manager);
    element->set_css_id(static_cast<int32_t>(arg1->Number()));
  };

  if (arg0->IsArrayOrJSArray()) {
    tasm::ForEachLepusValue(*arg0, std::move(looper));
  } else {
    looper(lepus::Value(), *arg0);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberFlushElementTree) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberFlushElementTree");
  // parameter size >= 0
  // [0] RefCounted -> element, flush the tree with the element as the root node
  // [1] Object -> options

  // If argc >= 1, convert arg0 to element.
  FiberElement* element = nullptr;
  if (argc >= 1) {
    CONVERT_ARG(arg0, 0);
    if (arg0->IsRefCounted()) {
      element =
          static_scoped_pointer_cast<FiberElement>(arg0->RefCounted()).Get();
    }
  }

  bool trigger_data_updated = false;
  // If argc >= 2, get PipelineOptions from arg1.
  // The options.triggerLayout's default value is true, set it to false if do
  // need call DispatchLayoutUpdates. The options.operationID's default value is
  // 0, if call __FiberFlushElementTree in componentAtIndex, please set
  // operationID to the value passed in componentAtIndex.
  tasm::PipelineOptions options;
  if (argc >= 2) {
    CONVERT_ARG(arg1, 1);
    if (arg1->IsObject()) {
      constexpr const static char* kTriggerLayout = "triggerLayout";
      if (arg1->Contains(kTriggerLayout)) {
        options.trigger_layout_ = arg1->GetProperty(kTriggerLayout).Bool();
      }
      constexpr const static char* kOperationID = "operationID";
      if (arg1->Contains(kOperationID)) {
        options.operation_id =
            static_cast<int64_t>(arg1->GetProperty(kOperationID).Number());
      }
      constexpr const static char* kTimingFlag = "__lynx_timing_flag";
      if (arg1->Contains(kTimingFlag)) {
        options.timing_flag = (arg1->GetProperty(kTimingFlag).String()->str());
      }
      constexpr const static char* kTriggerDataUpdated = "triggerDataUpdated";
      if (arg1->Contains(kTriggerDataUpdated)) {
        trigger_data_updated = arg1->GetProperty(kTriggerDataUpdated).Bool();
      }
    }
  }

  auto self = LEPUS_CONTEXT()->GetTasmPointer();

  tasm::TimingCollector::Scope<TemplateAssembler::Delegate> scope(
      &self->GetDelegate(), options.timing_flag);
  options.has_patched = true;
  self->page_proxy()->element_manager()->OnPatchFinishForFiber(options,
                                                               element);
  self->page_proxy()->element_manager()->painting_context()->FlushImmediately();

  // Currently, only client updateData, client resetData, and JS root component
  // setData updates trigger the OnDataUpdated callback, and only when the page
  // has actually changed. Other data updates, such as client reloadTemplate and
  // JS child components setData, do not trigger OnDataUpdated. In order to
  // align with this logic, the timing of OnDataUpdated is moved to the end of
  // FiberFlushElementTree, and it is controlled by LepusRuntime through
  // triggerDataUpdated.
  if (trigger_data_updated) {
    self->GetDelegate().OnDataUpdated();
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberOnLifecycleEvent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberOnLifecycleEvent");
  // parameter size = 1
  // [0] Array -> component event info
  CHECK_ARGC_GE(FiberOnLifecycleEvent, 1);
  CONVERT_ARG(arg0, 0);
  LEPUS_CONTEXT()->GetTasmPointer()->GetDelegate().OnLifecycleEvent(*arg0);
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberElementFromBinary) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElementFromBinary");
  // parameter size >= 2
  // [0] String -> template id
  // [1] Number -> component id
  CHECK_ARGC_EQ(FiberElementFromBinary, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, FiberElementFromBinary);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, FiberElementFromBinary);

  const auto& self = LEPUS_CONTEXT()->GetTasmPointer();
  const auto& entry = self->FindEntry(tasm::DEFAULT_ENTRY_NAME);
  const auto& info = entry->GetElementTemplateInfo(arg0->String()->str());

  lepus::Value node_ary = FiberElement::FromTemplateInfo(
      arg1->Int64(), self->page_proxy()->element_manager().get(), info);

  // Call manager->PrepareNodeForInspector to init inspector attr for the
  // element tree.
  EXEC_EXPR_FOR_INSPECTOR(
      constexpr const static char* kElements = "elements";
      tasm::ForEachLepusValue(
          node_ary.GetProperty(kElements),
          [manager = self->page_proxy()->element_manager().get()](
              const auto& index, const auto& value) {
            base::MoveOnlyClosure<void, FiberElement*> prepare_node_f(
                [manager, &prepare_node_f](const auto& element) {
                  manager->PrepareNodeForInspector(element);
                  for (const auto& child : element->children()) {
                    prepare_node_f(child.Get());
                  }
                });
            prepare_node_f(
                static_scoped_pointer_cast<FiberElement>(value.RefCounted())
                    .Get());
          }););

  RETURN(node_ary);
}

RENDERER_FUNCTION_CC(FiberElementFromBinaryAsync) {
  // TODO(songshourui.null): impl this later
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberQueryComponent) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberQueryComponent");
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  CHECK_ARGC_GE(FiberQueryComponent, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, FiberQueryComponent);
  auto entry = tasm->QueryComponent(arg0->String()->c_str());
  if (entry) {
    auto dictionary = lepus::Dictionary::Create();
    dictionary->SetValue("evalResult", entry->GetBinaryEvalResult());
    return lepus::Value(dictionary);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberQuerySelector) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberQuerySelector");
  CHECK_ARGC_GE(FiberQuerySelector, 3);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }
  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberQuerySelector);
  NodeSelectOptions options(NodeSelectOptions::IdentifierType::CSS_SELECTOR,
                            arg1->String()->str());
  CONVERT_ARG_AND_CHECK(arg2, 2, Object, FiberQuerySelector);
  auto only_current_component = arg2->GetProperty("onlyCurrentComponent");
  options.only_current_component =
      only_current_component.IsBool() ? only_current_component.Bool() : true;
  auto result = tasm::FiberElementSelector::Select(element.Get(), options);
  if (result.Success()) {
    RETURN(
        lepus::Value(base::scoped_refptr<FiberElement>(result.GetOneNode())));
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(FiberQuerySelectorAll) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberQuerySelectorAll");
  CHECK_ARGC_GE(FiberQuerySelectorAll, 3);
  CONVERT_ARG(arg0, 0);
  if (!arg0->IsRefCounted()) {
    RETURN_UNDEFINED();
  }
  auto element = static_scoped_pointer_cast<FiberElement>(arg0->RefCounted());
  CONVERT_ARG_AND_CHECK(arg1, 1, String, FiberQuerySelectorAll);
  NodeSelectOptions options(NodeSelectOptions::IdentifierType::CSS_SELECTOR,
                            arg1->String()->str());
  options.first_only = false;
  CONVERT_ARG_AND_CHECK(arg2, 2, Object, FiberQuerySelector);
  auto only_current_component = arg2->GetProperty("onlyCurrentComponent");
  options.only_current_component =
      only_current_component.IsBool() ? only_current_component.Bool() : true;
  auto result = tasm::FiberElementSelector::Select(element.Get(), options);

  auto ary = lepus::CArray::Create();
  for (const auto& c : result.nodes) {
    auto ref = base::scoped_refptr<FiberElement>(c);
    ary->push_back(lepus::Value(ref));
  }
  RETURN(lepus::Value(ary));
}

RENDERER_FUNCTION_CC(FiberSetLepusInitData) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberSetLepusInitData");
  // parameter size >= 1
  // [0] Object -> lepus init data
  CHECK_ARGC_GE(FiberSetLepusInitData, 1);
  CONVERT_ARG(arg0, 0);

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  if (tasm == nullptr) {
    RETURN_UNDEFINED();
  }
  const auto& entry = tasm->FindTemplateEntry(tasm::DEFAULT_ENTRY_NAME);
  if (entry == nullptr) {
    RETURN_UNDEFINED();
  }
  entry->SetLepusInitData(*arg0);
  RETURN_UNDEFINED();
}

/* Element API END */

RENDERER_FUNCTION_CC(SetSourceMapRelease) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetSourceMapRelease");
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  CHECK_ARGC_EQ(SendGlobalEvent, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, SetSourceMapRelease);
  if (tasm) {
    tasm->SetSourceMapRelease(*arg0);
  }
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(ReportError) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ReportError");
  if (LEPUS_CONTEXT()->IsLepusNGContext()) {
    CHECK_ARGC_GE(ReportError, 2);
    CONVERT_ARG_AND_CHECK(arg0, 0, Object, ReportError);
    CONVERT_ARG_AND_CHECK(arg1, 1, Object, ReportError);

    LEPUS_CONTEXT()->ReportErrorWithMsg(
        arg0->GetProperty("message").ToString(),
        arg0->GetProperty("stack").ToString(),
        static_cast<int>(arg1->GetProperty("errorCode").Number()));
  }
  RETURN_UNDEFINED();
}

void RendererFunctions::UpdateComponentConfig(TemplateAssembler* tasm,
                                              BaseComponent* component) {
  component->UpdateSystemInfo(GetSystemInfoFromTasm(tasm));
}

// This function is used to get internal attribute holder from a node.
AttributeHolder* RendererFunctions::GetInternalAttributeHolder(
    lepus::Context* context, lepus::Value* arg) {
  auto* base = reinterpret_cast<RadonBase*>(arg->CPoint());
  auto* node = static_cast<RadonNode*>(base);
  return node;
}

BaseComponent* RendererFunctions::GetBaseComponent(lepus::Context* context,
                                                   lepus::Value* arg) {
  auto* tasm = context->GetTasmPointer();
  if (tasm->page_proxy()->HasRadonPage()) {
    RadonBase* base = reinterpret_cast<RadonBase*>(arg->CPoint());
    if (base->IsRadonPage() || base->IsRadonComponent()) {
      return static_cast<RadonComponent*>(base);
    }
  }
  return nullptr;
}

/* AirElement API BEGIN */
RENDERER_FUNCTION_CC(AirCreateElement) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateElement");
  // parameter size >= 2
  // [0] String -> element's tag
  // [1] Number -> element's lepus_id
  CHECK_ARGC_GE(AirCreateElement, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, AirCreateElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirCreateElement);
  CONVERT_ARG_AND_CHECK(arg2, 2, Bool, AirCreateElement);

  const auto& tag = arg0->String();
  const auto& lepus_id = static_cast<int32_t>(arg1->Number());
  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();

  int32_t impl_id = -1;
  uint64_t key = 0;
  if (argc >= 10) {
    GET_IMPL_ID_AND_KEY(impl_id, 8, key, 9, AirCreateElement);
  }
  key = key > 0 ? key : manager->AirRoot()->GetKeyForCreatedElement(lepus_id);

  base::scoped_refptr<AirLepusRef> elementRef =
      manager->CreateAirNode(tag, lepus_id, impl_id, key);
  // While create_opt is on, attributes,styles,class,id,parent will be
  // compressed to one command.
  // for example:
  // image_node = __AirCreateElement(image, 2, true, {30: '75rpx'}, {src:
  // test_url}, product-cover, product_cover, $parent); Static inline style,
  // attribute, class, id would be converted to arg3, arg4, arg5, arg6 ,
  // respectively.
  bool create_opt = arg2->Bool();
  if (create_opt) {
    AirElement* element = elementRef->Get();
    CONVERT_ARG(arg3, 3);
    // style
    if (arg3->IsObject()) {
      tasm::ForEachLepusValue(
          *arg3, [element](const lepus::Value& key, const lepus::Value& value) {
            CSSPropertyID id =
                static_cast<CSSPropertyID>(std::stoi(key.String()->c_str()));
            if (CSSProperty::IsPropertyValid(id)) {
              tasm::StyleMap ret;
              tasm::UnitHandler::Process(
                  id, value, ret,
                  element->element_manager()->GetCSSParserConfigs());
              // key for aggregation css may change after UnitHandler::Process,
              // e.g.: kPropertyIDBorderBottom-> kPropertyIDBorderBottomStyle
              for (auto const& [css_id, css_value] : ret) {
                element->SetInlineStyle(css_id, css_value);
              }
            }
          });
    } else if (arg3->IsString()) {
      lepus::Value new_argv[] = {lepus::Value(elementRef), *arg3};
      AirSetInlineStyles(ctx, new_argv, 2);
    }
    CONVERT_ARG(arg4, 4);
    // attribute
    if (arg4->IsObject()) {
      tasm::ForEachLepusValue(
          *arg4, [element](const lepus::Value& key, const lepus::Value& value) {
            element->SetAttribute(key.String(), value);
          });
    }
    CONVERT_ARG(arg5, 5);
    // class
    if (arg5->IsString()) {
      element->SetClasses(*arg5);
    }
    CONVERT_ARG(arg6, 6);
    // id
    if (arg6->IsString()) {
      element->SetIdSelector(*arg6);
    }
    CONVERT_ARG(arg7, 7);
    if (arg7->IsRefCounted()) {
      auto parent =
          static_scoped_pointer_cast<AirLepusRef>(arg7->RefCounted())->Get();
      parent->InsertNode(element);
    } else if (arg7->IsNumber()) {
      // In the new proposal about Lepus Tree, the parameter `parent` is only a
      // number which represents the unique id of parent element.
      auto parent =
          manager->air_node_manager()->Get(static_cast<int>(arg7->Number()));
      if (parent) {
        parent->InsertNode(element);
      }
    }

    if (argc >= 12) {
      // In the new proposal about Lepus Tree, event and dataset are also
      // provided in the create operation.
      CONVERT_ARG_AND_CHECK(arg10, 10, Object, AirCreateElement);
      CONVERT_ARG_AND_CHECK(arg11, 11, Object, AirCreateElement);
      const auto& event_type =
          arg10->GetProperty(AirElement::kAirLepusEventType);
      const auto& event_name =
          arg10->GetProperty(AirElement::kAirLepusEventName);
      const auto& event_callback =
          arg10->GetProperty(AirElement::kAirLepusEventCallback);
      if (event_type.IsString() && event_name.IsString() &&
          event_callback.IsString()) {
        const auto& type = event_type.String();
        const auto& name = event_name.String();
        const auto& callback = event_callback.String();
        element->SetEventHandler(name, element->SetEvent(type, name, callback));
      }
      tasm::ForEachLepusValue(*arg11, [&element](const lepus::Value& key,
                                                 const lepus::Value& value) {
        element->SetDataSet(key.String(), value);
      });
    }
  }
  RETURN(lepus::Value(elementRef));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetElement) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetElement");
  CHECK_ARGC_GE(AirGetElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, AirGetElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirGetElement);

  const auto& tag = arg0->String();
  const auto& lepus_id = static_cast<int32_t>(arg1->Number());

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  auto result = manager->GetAirNode(tag, lepus_id);
  if (result) {
    RETURN(lepus::Value(result));
  }
  RETURN_UNDEFINED();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreatePage) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreatePage");
  // parameter size >= 2
  // [0] String -> componentID
  // [1] Number -> component/page's lepus id
  CHECK_ARGC_GE(AirCreatePage, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, AirCreatePage);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirCreatePage);

  constexpr static const char* kCard = "card";

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  auto page = manager->CreateAirPage(arg1->Int32());
  const auto& entry = self->FindEntry(tasm::DEFAULT_ENTRY_NAME);
  page->SetContext(self->context(tasm::DEFAULT_ENTRY_NAME));
  page->SetRadon(entry->compile_options().radon_mode_ ==
                 CompileOptionRadonMode::RADON_MODE_RADON);
  page->SetParsedStyles(entry->GetComponentParsedStyles(kCard));

  int tid = (int)arg1->Number();
  auto it = self->page_moulds().find(tid);
  PageMould* pm = it->second.get();
  page->DeriveFromMould(pm);

  RETURN(lepus::Value(
      AirLepusRef::Create(manager->air_node_manager()->Get(page->impl_id()))));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateComponent) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateComponent");
  CHECK_ARGC_GE(AirCreateComponent, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirCreateComponent);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, AirCreateComponent);
  CONVERT_ARG_AND_CHECK(arg2, 2, String, AirCreateComponent);
  CONVERT_ARG_AND_CHECK(arg3, 3, Number, AirCreateComponent);

  int32_t lepus_id = static_cast<int32_t>(arg3->Number());
  int tid = (int)arg0->Number();

  int32_t impl_id = -1;
  uint64_t key = 0;
  if (argc >= 6) {
    GET_IMPL_ID_AND_KEY(impl_id, 4, key, 5, AirCreateComponent);
  }

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  tasm::ElementManager* element_manager =
      self->page_proxy()->element_manager().get();

  lepus::Context* context = LEPUS_CONTEXT();
  auto cm_it = self->component_moulds(context).find(tid);
  DCHECK(cm_it != self->component_moulds(context).end());
  ComponentMould* cm = cm_it->second.get();

  std::shared_ptr<AirComponentElement> component =
      std::make_shared<AirComponentElement>(element_manager, tid, lepus_id,
                                            impl_id, LEPUS_CONTEXT());
  component->DeriveFromMould(cm);
  auto res = AirLepusRef::Create(component);
  key = key > 0 ? key
                : element_manager->AirRoot()->GetKeyForCreatedElement(lepus_id);
  element_manager->air_node_manager()->Record(component->impl_id(), component);
  element_manager->air_node_manager()->RecordForLepusId(component->GetLepusId(),
                                                        key, res);

  if (argc >= 7) {
    // In the new proposal about Lepus Tree, the unique id of parent element is
    // provided. This is to accomplish the insert operation in the create
    // function to reduce the number of render function calls.
    CONVERT_ARG(arg6, 6);
    if (arg6->IsNumber()) {
      auto parent = element_manager->air_node_manager()->Get(
          static_cast<int>(arg6->Number()));
      if (parent) {
        parent->InsertNode(component.get());
      }
    }
  }

  component->SetName(arg1->String());
  component->SetPath(arg2->String());

  const auto& entry = self->FindEntry(tasm::DEFAULT_ENTRY_NAME);
  component->SetParsedStyles(
      entry->GetComponentParsedStyles(arg2->String()->str()));

  RETURN(lepus::Value(res));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateBlock) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateBlock");
  // parameter size >= 1
  // [1] Number -> air element's lepus id
  CHECK_ARGC_GE(AirCreateBlock, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirCreateBlock);
  const auto& lepus_id = static_cast<int32_t>(arg0->Number());

  int32_t impl_id = -1;
  uint64_t key = 0;
  if (argc >= 3) {
    GET_IMPL_ID_AND_KEY(impl_id, 1, key, 2, AirCreateBlock);
  }

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  std::shared_ptr<AirBlockElement> block =
      std::make_shared<AirBlockElement>(manager.get(), lepus_id, impl_id);
  auto res = AirLepusRef::Create(block);
  key = key > 0 ? key : manager->AirRoot()->GetKeyForCreatedElement(lepus_id);
  manager->air_node_manager()->Record(block->impl_id(), block);
  manager->air_node_manager()->RecordForLepusId(block->GetLepusId(), key, res);

  if (argc >= 4) {
    // In the new proposal about Lepus Tree, the unique id of parent element is
    // provided to accomplish the create and insert operation in one render
    // function.
    CONVERT_ARG(arg3, 3);
    if (arg3->IsNumber()) {
      auto parent =
          manager->air_node_manager()->Get(static_cast<int>(arg3->Number()));
      if (parent) {
        parent->InsertNode(block.get());
      }
    }
  }

  RETURN(lepus::Value(res));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateIf) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateIf");
  // parameter size >= 1
  // [1] Number -> air element's lepus id
  CHECK_ARGC_GE(AirCreateIf, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirCreateIf);
  const auto& lepus_id = static_cast<int32_t>(arg0->Number());

  int32_t impl_id = -1;
  uint64_t key = 0;
  if (argc >= 3) {
    GET_IMPL_ID_AND_KEY(impl_id, 1, key, 2, AirCreateIf);
  }

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  std::shared_ptr<AirIfElement> if_element =
      std::make_shared<AirIfElement>(manager.get(), lepus_id, impl_id);
  auto res = AirLepusRef::Create(if_element);
  key = key > 0 ? key : manager->AirRoot()->GetKeyForCreatedElement(lepus_id);
  manager->air_node_manager()->Record(if_element->impl_id(), if_element);
  manager->air_node_manager()->RecordForLepusId(if_element->GetLepusId(), key,
                                                res);

  if (argc >= 5) {
    // In the new proposal about Lepus Tree, the unique id of parent element and
    // active branch index of tt:if are also provided.
    CONVERT_ARG(arg3, 3);
    if (arg3->IsNumber()) {
      auto parent =
          manager->air_node_manager()->Get(static_cast<int>(arg3->Number()));
      if (parent) {
        parent->InsertNode(if_element.get());
      }
    }
    CONVERT_ARG_AND_CHECK(arg4, 4, Number, AirCreateIf);
    if_element->UpdateIfIndex(static_cast<int32_t>(arg4->Number()));
  }

  RETURN(lepus::Value(res));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateRadonIf) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateRadonIf");
  // parameter size >= 1
  // [1] Number -> air element's lepus id
  CHECK_ARGC_GE(AirCreateRadonIf, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirCreateRadonIf);

  const auto& lepus_id = static_cast<int32_t>(arg0->Number());

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  std::shared_ptr<AirRadonIfElement> radon_if =
      std::make_shared<AirRadonIfElement>(manager.get(), lepus_id);

  auto res = AirLepusRef::Create(radon_if);
  uint64_t key = manager->AirRoot()->GetKeyForCreatedElement(lepus_id);
  manager->air_node_manager()->Record(radon_if->impl_id(), radon_if);
  manager->air_node_manager()->RecordForLepusId(radon_if->GetLepusId(), key,
                                                res);

  RETURN(lepus::Value(res));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateFor) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateFor");
  // parameter size >= 1
  // [1] Number -> air element's lepus id
  CHECK_ARGC_GE(AirCreateFor, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirCreateFor);
  const auto& lepus_id = static_cast<int32_t>(arg0->Number());

  int32_t impl_id = -1;
  uint64_t key = 0;
  if (argc >= 3) {
    GET_IMPL_ID_AND_KEY(impl_id, 1, key, 2, AirCreateFor);
  }

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  std::shared_ptr<AirForElement> for_element =
      std::make_shared<AirForElement>(manager.get(), lepus_id, impl_id);
  auto res = AirLepusRef::Create(for_element);
  key = key > 0 ? key : manager->AirRoot()->GetKeyForCreatedElement(lepus_id);
  manager->air_node_manager()->Record(for_element->impl_id(), for_element);
  manager->air_node_manager()->RecordForLepusId(for_element->GetLepusId(), key,
                                                res);

  if (argc >= 5) {
    // In the new proposal about Lepus Tree, the unique id of parent element and
    // child element count of tt:for are also provided.
    CONVERT_ARG(arg3, 3);
    if (arg3->IsNumber()) {
      auto parent =
          manager->air_node_manager()->Get(static_cast<int>(arg3->Number()));
      if (parent) {
        parent->InsertNode(for_element.get());
      }
    }
    CONVERT_ARG_AND_CHECK(arg4, 4, Number, AirCreateFor);
    for_element->UpdateChildrenCount(static_cast<uint32_t>(arg4->Number()));
  }

  RETURN(lepus::Value(res));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreatePlug) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreatePlug");
  // TODO(liuli) support plug and slot later
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateSlot) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateSlot");
  // TODO(liuli) support plug and slot later
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirAppendElement) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirAppendElement");
  // parameter size = 2
  // [0] ptr -> parent element
  // [1] ptr -> child element
  CHECK_ARGC_EQ(AirAppendElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirAppendElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, AirAppendElement);
  auto parent =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  auto child =
      static_scoped_pointer_cast<AirLepusRef>(arg1->RefCounted())->Get();
  if (child->parent() != nullptr) {
    RETURN_UNDEFINED();
  }
  parent->InsertNode(child);
  RETURN(lepus::Value(child));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirRemoveElement) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirRemoveElement");
  // parameter size = 2
  // [0] ptr -> parent element
  // [1] ptr -> child element
  CHECK_ARGC_EQ(AirRemoveElement, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirRemoveElement);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, AirRemoveElement);
  auto parent =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  auto child =
      static_scoped_pointer_cast<AirLepusRef>(arg1->RefCounted())->Get();
  parent->RemoveNode(child);
  RETURN(lepus::Value(child));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirInsertElementBefore) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirInsertElementBefore");
  // parameter size = 3
  // [0] ptr -> parent element
  // [1] ptr -> child element
  // [2] ptr|null|Undefined -> ref element
  CHECK_ARGC_EQ(AirInsertElementBefore, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirInsertElementBefore);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, AirInsertElementBefore);
  CONVERT_ARG(arg2, 2)
  auto parent =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  auto child =
      static_scoped_pointer_cast<AirLepusRef>(arg1->RefCounted())->Get();
  if (arg2 && arg2->RefCounted()) {
    auto ref =
        static_scoped_pointer_cast<AirLepusRef>(arg2->RefCounted())->Get();
    parent->InsertNodeBefore(child, ref);
  } else {
    parent->InsertNode(child);
  }
  RETURN(lepus::Value(child));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetElementUniqueID) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetElementUniqueID");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_EQ(AirGetElementUniqueID, 1);
  CONVERT_ARG(arg0, 0);

  int64_t unique_id = -1;
  if (arg0->RefCounted()) {
    auto* element =
        static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
    unique_id = element->impl_id();
  }
  RETURN(lepus::Value(unique_id));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetElementTag) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetElementTag");
  // parameter size = 1
  // [0] RefCounted -> element
  CHECK_ARGC_EQ(AirGetElementTag, 1);
  CONVERT_ARG(arg0, 0);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  RETURN(lepus::Value(element->GetTag().c_str()));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetAttribute) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetAttribute");
  // parameter size = 3
  // [0] ptr -> element
  // [1] String -> key
  // [2] any -> value
  CHECK_ARGC_EQ(AirSetAttribute, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetAttribute);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, AirSetAttribute);
  CONVERT_ARG(arg2, 2)

  auto element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  element->SetAttribute(arg1->String(), *arg2);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetInlineStyles) {
#if ENABLE_AIR
  // parameter size = 2
  // [0] ptr -> element
  // [1] value -> styles
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetInlineStyles");
  CHECK_ARGC_EQ(AirSetInlineStyles, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetInlineStyles);
  CONVERT_ARG(arg1, 1);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  auto style_value = arg1->String();
  auto splits = base::SplitStringByCharsOrderly(style_value->str(), {':', ';'});
  for (size_t i = 0; i + 1 < splits.size(); i += 2) {
    std::string key = base::TrimString(splits[i]);
    std::string value = base::TrimString(splits[i + 1]);
    CSSPropertyID id = CSSProperty::GetPropertyID(key);
    if (CSSProperty::IsPropertyValid(id)) {
      auto css_values = UnitHandler::Process(
          id, lepus::Value(lepus::StringImpl::Create(value)),
          element->element_manager()->GetCSSParserConfigs());
      for (auto const& [css_id, css_value] : css_values) {
        element->SetInlineStyle(css_id, css_value);
      }
    }
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetEvent) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetEvent");
  CHECK_ARGC_EQ(AirSetEvent, 4);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetEvent);
  CONVERT_ARG_AND_CHECK(type, 1, String, AirSetEvent);
  CONVERT_ARG_AND_CHECK(name, 2, String, AirSetEvent);
  CONVERT_ARG(callback, 3);
  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  const auto& type_str = type->String();
  const auto& name_str = name->String();
  if (callback->IsString()) {
    element->SetEventHandler(
        name_str, element->SetEvent(type_str, name_str, callback->String()));
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetID) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetID");
  CHECK_ARGC_EQ(AirSetID, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, SetId);
  CONVERT_ARG(arg1, 1);

  // if arg1 is not a String, it will return empty string
  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  element->SetIdSelector(*arg1);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetElementByID) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetElementByID");
  CHECK_ARGC_EQ(AirGetElementByID, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, AirGetElementByID);
  const auto& id = arg0->String();

  if (!id->empty()) {
    auto* self = LEPUS_CONTEXT()->GetTasmPointer();
    auto& manager = self->page_proxy()->element_manager();
    auto element = manager->air_node_manager()->GetCustomId(id->c_str());
    RETURN(lepus::Value(AirLepusRef::Create(element)));
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetElementByUniqueID) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetElementByUniqueID");
  CHECK_ARGC_EQ(AirGetElementByUniqueID, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirGetElementByUniqueID);
  int id = static_cast<int>(arg0->Number());

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  auto element = manager->air_node_manager()->Get(id);
  if (element) {
    RETURN(lepus::Value(AirLepusRef::Create(element)));
  } else {
    RETURN_UNDEFINED();
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetRootElement) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetRootElement");

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  AirElement* element = static_cast<AirElement*>(manager->AirRoot());
  if (element) {
    RETURN((lepus::Value(AirLepusRef::Create(
        manager->air_node_manager()->Get(element->impl_id())))));
  } else {
    RETURN_UNDEFINED();
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetElementByLepusID) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetElementByLepusID");
  CHECK_ARGC_EQ(AirGetElementByLepusID, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirGetElementByLepusID);

  int tag = static_cast<int>(arg0->Int64());

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  auto array = lepus::CArray::Create();
  AirPageElement* page = manager->AirRoot();
  auto* cur_for_element = page->GetCurrentForElement();
  auto* cur_component_element = page->GetCurrentComponentElement();
  if (cur_component_element) {
    if (!cur_for_element ||
        (cur_for_element &&
         cur_component_element->GetLepusId() > cur_for_element->GetLepusId())) {
      auto elements = manager->air_node_manager()->GetAllNodesForLepusId(tag);
      for (auto& element : elements) {
        if (element->Get()->GetParentComponent() == cur_component_element) {
          array->push_back(lepus::Value(element));
        }
      }
    } else if (cur_for_element) {
      uint64_t key = page->GetKeyForCreatedElement(tag);
      auto node = manager->air_node_manager()->GetForLepusId(tag, key);
      if (node) {
        array->push_back(lepus::Value(node));
      }
    }
  } else if (cur_for_element) {
    uint64_t key = page->GetKeyForCreatedElement(tag);
    auto node = manager->air_node_manager()->GetForLepusId(tag, key);
    if (node) {
      array->push_back(lepus::Value(node));
    }
  } else {
    auto elements = manager->air_node_manager()->GetAllNodesForLepusId(tag);
    for (auto& element : elements) {
      array->push_back(lepus::Value(element));
    }
  }

  RETURN(lepus::Value(array));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirUpdateIfNodeIndex) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirUpdateIfNodeIndex");
  CHECK_ARGC_EQ(AirUpdateIfNodeIndex, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirUpdateIfNodeIndex);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirUpdateIfNodeIndex);

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  int32_t index = static_cast<int32_t>(arg1->Int64());
  AirElementType type = element->GetElementType();
  if (type == kAirIf) {
    auto* if_element = static_cast<AirIfElement*>(element);
    if_element->UpdateIfIndex(index);
    RETURN_UNDEFINED();
  } else if (type == kAirRadonIf) {
    auto* if_element = static_cast<AirRadonIfElement*>(element);
    auto* update_element = if_element->UpdateIfIndex(index);
    if (update_element) {
      RETURN(lepus::Value(AirLepusRef::Create(
          manager->air_node_manager()->Get(update_element->impl_id()))));
    } else {
      RETURN_UNDEFINED();
    }
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirUpdateForNodeIndex) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirUpdateForNodeIndex");
  CHECK_ARGC_EQ(AirUpdateForNodeIndex, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirUpdateForNodeIndex);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirUpdateForNodeIndex);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  if (element->is_for()) {
    uint32_t index = static_cast<uint32_t>(arg1->Int64());
    static_cast<AirForElement*>(element)->UpdateActiveIndex(index);
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirUpdateForChildCount) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirUpdateForChildCount");
  CHECK_ARGC_EQ(AirUpdateForChildCount, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirUpdateForChildCount);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirUpdateForChildCount);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  if (element->is_for()) {
    uint32_t count = static_cast<uint32_t>(arg1->Number());
    static_cast<AirForElement*>(element)->UpdateChildrenCount(count);
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetForNodeChildWithIndex) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetForNodeChildWithIndex");
  CHECK_ARGC_GE(AirGetForNodeChildWithIndex, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirGetForNodeChildWithIndex);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirGetForNodeChildWithIndex);

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  auto* node = static_cast<AirForElement*>(
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get());
  uint32_t index = arg1->Number();
  auto* active_node = node->GetForNodeChildWithIndex(index);
  RETURN(lepus::Value(AirLepusRef::Create(
      manager->air_node_manager()->Get(active_node->impl_id()))));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirPushForNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirPushForNode");
  CHECK_ARGC_EQ(AirPushForNode, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirPushForNode);

  auto* element = static_cast<AirForElement*>(
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get());
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  manager->AirRoot()->PushForElement(element);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirPopForNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirPopForNode");

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  manager->AirRoot()->PopForElement();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetChildElementByIndex) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetChildElementByIndex");
  CHECK_ARGC_EQ(AirGetChildElementByIndex, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirGetChildElementByIndex);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirGetChildElementByIndex);

  auto* ele =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  uint32_t index = static_cast<uint32_t>(arg1->Number());

  auto* child = ele->GetChildAt(index);

  if (child) {
    RETURN(lepus::Value(child));
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirPushDynamicNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirPushDynamicNode");
  CHECK_ARGC_GE(PushDynamicNode, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, PushDynamicNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, RefCounted, PushDynamicNode);

  auto* node =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  auto* child =
      static_scoped_pointer_cast<AirLepusRef>(arg1->RefCounted())->Get();
  node->PushDynamicNode(child);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetDynamicNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetDynamicNode");
  CHECK_ARGC_GE(AirGetDynamicNode, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirGetDynamicNode);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, AirGetDynamicNode);
  CONVERT_ARG_AND_CHECK(arg2, 2, Number, AirGetDynamicNode);

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();

  auto* node =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  uint32_t index = arg1->Number();
  uint32_t node_index = arg2->Number();
  auto* element = node->GetDynamicNode(index, node_index);
  RETURN(lepus::Value(AirLepusRef::Create(
      manager->air_node_manager()->Get(element->impl_id()))));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetComponentProp) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetComponentProp");
  CHECK_ARGC_EQ(AirSetComponentProp, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetComponentProp);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, AirSetComponentProp);
  CONVERT_ARG(arg2, 2);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  if (element->is_component()) {
    lepus::String key = arg1->String();
    static_cast<AirComponentElement*>(element)->SetProperty(key, *arg2);
  }

#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirRenderComponentInLepus) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirRenderComponentInLepus");
  DCHECK(ARGC() == 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirRenderComponentInLepus);

  auto* component = static_cast<AirComponentElement*>(
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get());
  component->CreateComponentInLepus();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirUpdateComponentInLepus) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirUpdateComponentInLepus");
  CHECK_ARGC_GE(AirUpdateComponentInLepus, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirUpdateComponentInLepus);
  CONVERT_ARG_AND_CHECK(arg1, 1, Object, AirUpdateComponentInLepus);

  auto* component = static_cast<AirComponentElement*>(
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get());
  component->UpdateComponentInLepus(*arg1);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetComponentInfo) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetComponentInfo");
  CHECK_ARGC_EQ(AirGetComponentInfo, 1);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirUpdateComponentInfo) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirUpdateComponentInfo");
  CHECK_ARGC_GE(AirUpdateComponentInfo, 4);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetData) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetData");
  CHECK_ARGC_EQ(AirGetData, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirGetData);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  RETURN(lepus::Value(element->GetData()));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetProps) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetProps");
  CHECK_ARGC_EQ(AirGetProps, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirGetProps);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  RETURN(lepus::Value(element->GetProperties()));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetData) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetData");
  CHECK_ARGC_GE(AirSetData, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetData);
  CONVERT_ARG(arg1, 1);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  AirElement* component;
  if (element->is_page() || element->is_component()) {
    component = element;
  } else {
    component = element->GetParentComponent();
  }

  if (component && component->is_page()) {
    auto* page = static_cast<AirPageElement*>(component);
    UpdatePageOption update_option;
    update_option.update_first_time = false;
    update_option.from_native = false;
    page->UpdatePageData(*arg1, update_option);
  } else if (component && component->is_component()) {
    static_cast<AirComponentElement*>(component)->SetData(*arg1);
  }
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirFlushElement) {
#if ENABLE_AIR
  // parameter size == 1
  // [0] RefCounted -> air element
  CHECK_ARGC_EQ(AirFlushElement, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirFlushElement);

  auto element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  element->FlushProps();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirFlushElementTree) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirFlushRecursively");
  CHECK_ARGC_EQ(AirFlushRecursively, 1);

  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirFlushRecursively);
  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  element->FlushRecursively();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(TriggerLepusBridge) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TriggerLepusBridge");
  CHECK_ARGC_GE(TriggerLepusBridge, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, TriggerLepusBridge);

  constexpr const static char* kCallAsync = "call";
  constexpr const static char* kEventDetail = "methodDetail";
  constexpr const static char* kEventEntryName = "tasmEntryName";

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();

  auto dictionary = lepus::Dictionary::Create();
  dictionary->SetValue(kEventDetail, *arg0);
  const char* current_name = LEPUS_CONTEXT()->name().c_str();
  dictionary->SetValue(kEventEntryName, lepus::Value(current_name));
  lepus::Value param;
  param.SetTable(dictionary);
  if (ARGC() == 1) {
    if (LEPUS_CONTEXT()->IsLepusNGContext()) {
      constexpr const static auto default_callback =
          [](LEPUSContext* context, LEPUSValue value, int argc,
             LEPUSValue* argv) -> LEPUSValue { return LEPUS_UNDEFINED; };
      constexpr const static char* kCallback = "callback";
      tasm->TriggerBridgeAsync(
          LEPUS_CONTEXT(), kCallAsync, param,
          std::make_unique<lepus::Value>(
              LEPUS_CONTEXT()->context(),
              LEPUS_NewCFunction(LEPUS_CONTEXT()->context(), default_callback,
                                 kCallback, 0)));
    } else {
      tasm->TriggerBridgeAsync(
          LEPUS_CONTEXT(), kCallAsync, param,
          std::make_unique<lepus::Value>(
              lepus::Closure::Create(lepus::Function::Create())));
    }

  } else {
    CONVERT_ARG_AND_CHECK(arg1, 1, Callable, TriggerLepusBridge);
    tasm->TriggerBridgeAsync(LEPUS_CONTEXT(), kCallAsync, param,
                             std::make_unique<lepus::Value>(*arg1));
  }
#endif
  RETURN_UNDEFINED()
}

RENDERER_FUNCTION_CC(TriggerLepusBridgeSync) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TriggerLepusBridgeSync");
  CHECK_ARGC_GE(TriggerLepusBridge, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, TriggerLepusBridge);

  constexpr const static char* kCallSync = "callSync";
  constexpr const static char* kEventDetail = "methodDetail";
  constexpr const static char* kEventEntryName = "tasmEntryName";
  constexpr const static char* kEventComponentId = "componentId";

  auto dictionary = lepus::Dictionary::Create();
  dictionary->SetValue(kEventDetail, *arg0);
  dictionary->SetValue(kEventComponentId, lepus::Value(0));
  const char* current_name = LEPUS_CONTEXT()->name().c_str();
  dictionary->SetValue(kEventEntryName, lepus::Value(current_name));
  lepus::Value param;
  param.SetTable(dictionary);

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  lepus::Value value = tasm->TriggerBridgeSync(kCallSync, param);

  RETURN(value);
#endif
  RETURN_UNDEFINED()
}

RENDERER_FUNCTION_CC(AirSetDataSet) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetDataSet");
  CHECK_ARGC_EQ(AirSetDataSet, 3);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetDataSet);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, AirSetDataSet);
  CONVERT_ARG(arg2, 2);

  auto key = arg1->String();
  auto value = CONVERT(arg2);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  element->SetDataSet(key, value);
#endif
  RETURN_UNDEFINED()
}

RENDERER_FUNCTION_CC(AirSendGlobalEvent) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSendGlobalEvent");
  CHECK_ARGC_EQ(AirSendGlobalEvent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, AirSendGlobalEvent);
  CONVERT_ARG(arg1, 1);
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  tasm->SendGlobalEventToLepus(arg0->String()->str(), *arg1);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(RemoveEventListener) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RemoveEventListener");
  CHECK_ARGC_GE(RemoveEventListener, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, RemoveEventListener);
  auto* tasm = LEPUS_CONTEXT()->GetTasmPointer();
  std::string name = arg0->String()->str();
  tasm->RemoveLepusEventListener(name);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetTimeout) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetTimeout");
  CHECK_ARGC_GE(SetTimeout, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, Callable, SetTimeout);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, SetTimeout);

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  uint32_t task_id = tasm->SetTimeOut(
      LEPUS_CONTEXT(), std::make_unique<lepus::Value>(*arg0), arg1->Int64());
  lepus::Value value(static_cast<int64_t>(task_id));
  RETURN(value);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(ClearTimeout) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ClearTimeout");
  CHECK_ARGC_GE(ClearTimeout, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, ClearTimeout);

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  tasm->RemoveTimeTask(static_cast<uint32_t>(arg0->Int64()));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(SetTimeInterval) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "SetTimeInterval");
  CHECK_ARGC_GE(SetTimeInterval, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, Callable, SetTimeInterval);
  CONVERT_ARG_AND_CHECK(arg1, 1, Number, SetTimeInterval);
  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  uint32_t task_id = tasm->SetTimeInterval(
      LEPUS_CONTEXT(), std::make_unique<lepus::Value>(*arg0), arg1->Int64());
  lepus::Value value(static_cast<int64_t>(task_id));
  RETURN(value);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(ClearTimeInterval) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ClearTimeInterval");
  CHECK_ARGC_GE(ClearTimeInterval, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, ClearTimeInterval);

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  tasm->RemoveTimeTask(static_cast<uint32_t>(arg0->Int64()));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(TriggerComponentEvent) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TriggerComponentEvent");
  CHECK_ARGC_GE(TriggerComponentEvent, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, String, TriggerComponentEvent);
  CONVERT_ARG_AND_CHECK(arg1, 1, Object, TriggerComponentEvent);

  auto tasm = LEPUS_CONTEXT()->GetTasmPointer();
  tasm->TriggerComponentEvent(arg0->String()->str(), *arg1);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirCreateRawText) {
#if ENABLE_AIR
  constexpr const static char* kRawText = "raw-text";
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirCreateRawText");
  CHECK_ARGC_GE(AirCreateRawText, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, Number, AirCreateRawText);
  const auto& lepus_id = static_cast<int32_t>(arg0->Number());
  int32_t impl_id = -1;
  uint64_t key = 0;
  if (argc >= 5) {
    GET_IMPL_ID_AND_KEY(impl_id, 3, key, 4, AirCreateRawText);
  }

  auto& manager =
      LEPUS_CONTEXT()->GetTasmPointer()->page_proxy()->element_manager();
  key = key > 0 ? key : manager->AirRoot()->GetKeyForCreatedElement(lepus_id);
  auto elementRef = manager->CreateAirNode(kRawText, lepus_id, impl_id, key);
  if (argc >= 3) {
    CONVERT_ARG_AND_CHECK(arg1, 1, Object, AirCreateRawText);
    CONVERT_ARG(arg2, 2);
    AirElement* element = elementRef->Get();
    tasm::ForEachLepusValue(
        *arg1, [element](const lepus::Value& key, const lepus::Value& value) {
          element->SetAttribute(key.String(), value);
        });
    if (arg2->IsRefCounted()) {
      auto parent =
          static_scoped_pointer_cast<AirLepusRef>(arg2->RefCounted())->Get();
      parent->InsertNode(element);
    } else if (arg2->IsNumber()) {
      // In the new proposal about Lepus Tree, the third parameter is the unique
      // id of parent element.
      auto parent =
          manager->air_node_manager()->Get(static_cast<int>(arg2->Number()));
      if (parent) {
        parent->InsertNode(element);
      }
    }
  }
  RETURN(lepus::Value(elementRef));
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirSetClasses) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetClasses");
  CHECK_ARGC_EQ(AirSetClasses, 2);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirSetClasses);
  CONVERT_ARG_AND_CHECK(arg1, 1, String, AirSetClasses);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  element->SetClasses(*arg1);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirPushComponentNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirPushComponentNode");
  CHECK_ARGC_EQ(AirPushComponentNode, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirPushComponentNode);

  auto* element = static_cast<AirComponentElement*>(
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get());
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  manager->AirRoot()->PushComponentElement(element);
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirPopComponentNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirPopComponentNode");

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  manager->AirRoot()->PopComponentElement();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirGetParentForNode) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirGetParentForNode");
  CHECK_ARGC_GE(AirGetParentForNode, 1);
  CONVERT_ARG_AND_CHECK(arg0, 0, RefCounted, AirGetParentForNode);

  auto* element =
      static_scoped_pointer_cast<AirLepusRef>(arg0->RefCounted())->Get();
  auto* parent_component_element = element->GetParentComponent();
  auto* air_parent = element->air_parent();
  AirElement* for_node = nullptr;
  while (air_parent != parent_component_element) {
    if (air_parent->is_for()) {
      for_node = air_parent;
      break;
    }
    air_parent = air_parent->air_parent();
  }

  if (for_node) {
    auto* self = LEPUS_CONTEXT()->GetTasmPointer();
    auto& manager = self->page_proxy()->element_manager();
    return lepus::Value(AirLepusRef::Create(
        manager->air_node_manager()->Get(for_node->impl_id())));
  }
  RETURN_UNDEFINED();
#endif
  RETURN_UNDEFINED();
}

RENDERER_FUNCTION_CC(AirFlushTree) {
#if ENABLE_AIR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirFlushTree");
  CONVERT_ARG_AND_CHECK(arg0, 0, Object, AirFlushTree);

  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  int page_impl_id = manager->AirRoot()->impl_id();

  // arg0 is an object, the key is an interger and value is an array of lepus
  // elements. The key has the following situations:
  // 1. key is equal to unique id of root node, which means that it is the first
  // screen flush.
  // 2. key is less than 0, which means that all the nodes in value need to be
  // updated separately.
  // 3. in other cases, key represents the root node id of element subtree.
  tasm::ForEachLepusValue(*arg0, [ctx, &manager, page_impl_id](
                                     const lepus::Value& key,
                                     const lepus::Value& value) {
    std::string key_str = key.String()->str();
    int key_id = 0;
    bool ret = base::StringToInt(key_str, &key_id, 10);
    if (!ret) {
      return;
    }
    if (key_id < 0) {
      // flush every single element
      tasm::ForEachLepusValue(value, [ctx](const lepus::Value& idx,
                                           const lepus::Value& lepus_element) {
        UpdateAirElement(ctx, lepus_element, true);
      });
    } else if (key_id == page_impl_id) {
      // first screen
      tasm::ForEachLepusValue(value, [ctx](const lepus::Value& idx,
                                           const lepus::Value& lepus_element) {
        CreateAirElement(ctx, lepus_element);
      });
      manager->AirRoot()->FlushRecursively();
    } else {
      // flush subtree
      tasm::ForEachLepusValue(value, [ctx](const lepus::Value& idx,
                                           const lepus::Value& lepus_element) {
        auto flush_op =
            static_cast<int>(lepus_element.GetProperty("flushOp").Number());
        if (flush_op == 1) {
          CreateAirElement(ctx, lepus_element);
        } else if (flush_op == 0) {
          UpdateAirElement(ctx, lepus_element, false);
        }
      });
      manager->air_node_manager()->Get(key_id)->FlushRecursively();
    }
  });
#endif
  RETURN_UNDEFINED();
}

void RendererFunctions::UpdateAirElement(lepus::Context* ctx,
                                         const lepus::Value& lepus_element,
                                         bool need_flush) {
#if ENABLE_AIR
  auto* self = LEPUS_CONTEXT()->GetTasmPointer();
  auto& manager = self->page_proxy()->element_manager();
  auto impl_id = static_cast<int>(
      lepus_element.GetProperty(AirElement::kAirLepusUniqueId).Number());
  auto bits = static_cast<int>(
      lepus_element.GetProperty(AirElement::kAirLepusContentBits).Number());
  auto type = static_cast<int>(
      lepus_element.GetProperty(AirElement::kAirLepusType).Number());
  auto element = manager->air_node_manager()->Get(impl_id);
  if (!element) {
    return;
  }
  // update tt:if and tt:for
  switch (type) {
    case kAirIf: {
      auto index = static_cast<int32_t>(
          lepus_element.GetProperty(AirElement::kAirLepusIfIndex).Number());
      static_cast<AirIfElement*>(element.get())->UpdateIfIndex(index);
      break;
    }
    case kAirFor: {
      auto count = static_cast<uint32_t>(
          lepus_element.GetProperty(AirElement::kAirLepusForCount).Number());
      static_cast<AirForElement*>(element.get())->UpdateChildrenCount(count);
      break;
    }
    default: {
      break;
    }
  }
  // The value of bits is updated in lepus, each bit of bits indicates which
  // content has been updated.
  // 1. if bits & 00000001, inline styles is updated in lepus;
  // 2. if bits & 00000010, attributes are updated in lepus;
  // 3. if bits & 00000100, classes are updated in lepus;
  // 4. if bits & 00001000, id selector is updated in lepus;
  // 5. if bits & 00010000, event is updated in lepus;
  // 6. if bits & 00100000, dataset is updated in lepus.
  // update inline styles
  if (bits & (1 << 0)) {
    const auto& inline_styles =
        lepus_element.GetProperty(AirElement::kAirLepusInlineStyle);
    lepus::Value new_argv[] = {lepus::Value(AirLepusRef::Create(element)),
                               inline_styles};
    AirSetInlineStyles(ctx, new_argv, 2);
  }
  // update attributes
  if (bits & (1 << 1)) {
    const auto& attrs = lepus_element.GetProperty(AirElement::kAirLepusAttrs);
    tasm::ForEachLepusValue(attrs, [&element](const lepus::Value& attr_key,
                                              const lepus::Value& attr_value) {
      element->SetAttribute(attr_key.String(), attr_value);
    });
  }
  // update classes
  if (bits & (1 << 2)) {
    const auto& classes =
        lepus_element.GetProperty(AirElement::kAirLepusClasses);
    element->SetClasses(classes);
  }
  // update id selector
  if (bits & (1 << 3)) {
    const auto& id = lepus_element.GetProperty(AirElement::kAirLepusIdSelector);
    element->SetIdSelector(id);
  }
  // update event
  if (bits & (1 << 4)) {
    const auto& event = lepus_element.GetProperty(AirElement::kAirLepusEvent);
    const auto& event_type = event.GetProperty(AirElement::kAirLepusEventType);
    const auto& event_name = event.GetProperty(AirElement::kAirLepusEventName);
    const auto& event_callback =
        event.GetProperty(AirElement::kAirLepusEventCallback);
    if (event_type.IsString() && event_name.IsString() &&
        event_callback.IsString()) {
      const auto& type = event_type.String();
      const auto& name = event_name.String();
      const auto& callback = event_callback.String();
      element->SetEventHandler(name, element->SetEvent(type, name, callback));
    }
  }
  // update dataset
  if (bits & (1 << 5)) {
    const auto& dataset =
        lepus_element.GetProperty(AirElement::kAirLepusDataset);
    tasm::ForEachLepusValue(
        dataset, [&element](const lepus::Value& data_key,
                            const lepus::Value& data_value) {
          element->SetDataSet(data_key.String(), data_value);
        });
  }
  if (need_flush) {
    element->FlushProps();
  }
#endif
}

void RendererFunctions::CreateAirElement(lepus::Context* ctx,
                                         const lepus::Value& lepus_element) {
#if ENABLE_AIR
  // Create air element according to the property of lepus element.
  const auto& lepus_id = lepus_element.GetProperty(AirElement::kAirLepusId);
  const auto& impl_id =
      lepus_element.GetProperty(AirElement::kAirLepusUniqueId);
  const auto& lepus_key = lepus_element.GetProperty(AirElement::kAirLepusKey);
  const auto& parent = lepus_element.GetProperty(AirElement::kAirLepusParent);
  const auto& type = static_cast<int>(
      lepus_element.GetProperty(AirElement::kAirLepusType).Number());
  switch (type) {
    case kAirComponent: {
      const auto& name =
          lepus_element.GetProperty(AirElement::kAirLepusComponentName);
      const auto& path =
          lepus_element.GetProperty(AirElement::kAirLepusComponentPath);
      const auto& tid =
          lepus_element.GetProperty(AirElement::kAirLepusComponentTid);
      lepus::Value new_argv[] = {tid,     name,      path,  lepus_id,
                                 impl_id, lepus_key, parent};
      AirCreateComponent(ctx, new_argv, 7);
      break;
    }
    case kAirIf: {
      const auto& index =
          lepus_element.GetProperty(AirElement::kAirLepusIfIndex);
      lepus::Value new_argv[] = {lepus_id, impl_id, lepus_key, parent, index};
      AirCreateIf(ctx, new_argv, 5);
      break;
    }
    case kAirFor: {
      const auto& child_count =
          lepus_element.GetProperty(AirElement::kAirLepusForCount);
      lepus::Value new_argv[] = {lepus_id, impl_id, lepus_key, parent,
                                 child_count};
      AirCreateFor(ctx, new_argv, 5);
      break;
    }
    case kAirBlock: {
      lepus::Value new_argv[] = {lepus_id, impl_id, lepus_key, parent};
      AirCreateBlock(ctx, new_argv, 4);
      break;
    }
    case kAirRawText: {
      const auto& attrs = lepus_element.GetProperty(AirElement::kAirLepusAttrs);
      lepus::Value new_argv[] = {lepus_id, attrs, parent, impl_id, lepus_key};
      AirCreateRawText(ctx, new_argv, 5);
      break;
    }
    case kAirNormal: {
      const auto& tag = lepus_element.GetProperty(AirElement::kAirLepusTag);
      const auto& use_opt =
          lepus_element.GetProperty(AirElement::kAirLepusUseOpt);
      const auto& inline_styles =
          lepus_element.GetProperty(AirElement::kAirLepusInlineStyle);
      const auto& attrs = lepus_element.GetProperty(AirElement::kAirLepusAttrs);
      const auto& classes =
          lepus_element.GetProperty(AirElement::kAirLepusClasses);
      const auto& id =
          lepus_element.GetProperty(AirElement::kAirLepusIdSelector);
      const auto& event = lepus_element.GetProperty(AirElement::kAirLepusEvent);
      const auto& dataset =
          lepus_element.GetProperty(AirElement::kAirLepusDataset);
      lepus::Value new_argv[] = {tag,     lepus_id,  use_opt, inline_styles,
                                 attrs,   classes,   id,      parent,
                                 impl_id, lepus_key, event,   dataset};
      AirCreateElement(ctx, new_argv, 12);
      break;
    }
    default: {
      break;
    }
  }
#endif
}

}  // namespace tasm
}  // namespace lynx
