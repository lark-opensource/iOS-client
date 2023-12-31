// Copyright 2019 The Lynx Authors. All rights reserved.
#include <assert.h>

#include <sstream>

#include "base/log/logging.h"
#include "base/ref_counted.h"
#include "base/string/string_utils.h"
#include "config/config.h"
#include "css/css_style_sheet_manager.h"
#include "lepus/builtin.h"
#include "tasm/renderer.h"
#include "tasm/renderer_functions.h"
#if !defined(BUILD_LEPUS)
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_node.h"
#endif
#ifndef BUILD_LEPUS
#include "tasm/lynx_trace_event.h"
#endif

#ifndef BUILD_LEPUS
#include "tasm/react/element_manager.h"
#endif

namespace lynx {
namespace tasm {
namespace {}  // namespace
#define RENDERER_FUNCTION(name)                                       \
  static LEPUSValue name(LEPUSContext* ctx, LEPUSValueConst this_val, \
                         int argc, LEPUSValueConst* argv)

__attribute__((unused)) static void PrepareArgs(LEPUSContext* ctx,
                                                LEPUSValueConst* argv,
                                                lepus::Value* largv, int argc) {
  for (int i = 0; i < argc; i++) {
    new (largv + i) lepus::Value(ctx, argv[i]);
  }
}

__attribute__((unused)) static void FreeArgs(lepus::Value* largv, int argc) {
  for (int i = 0; i < argc; i++) {
    (largv + i)->FreeValue();
  }
}

#define PREPARE_ARGS(name)                                         \
  char args_buf[sizeof(lepus::Value) * argc];                      \
  lepus::Value* largv = reinterpret_cast<lepus::Value*>(args_buf); \
  PrepareArgs(ctx, argv, largv, argc);

#define CALL_RUNTIME_AND_RETURN(name)                                      \
  LEPUSValue ret = RendererFunctions::name(                                \
                       lepus::Context::GetFromJsContext(ctx), largv, argc) \
                       .ToJSValue(ctx);                                    \
  FreeArgs(largv, argc);                                                   \
  return ret;

#define CREATE_FUNCTION(name) \
  RENDERER_FUNCTION(name) { return LEPUS_UNDEFINED; }

#include "tasm/renderer_template.h"

#undef RENDERER_FUNCTION
#undef PREPARE_ARGS
#undef CALL_RUNTIME_AND_RETURN

#define RENDERER_FUNCTION(name)                                       \
  static LEPUSValue name(LEPUSContext* ctx, LEPUSValueConst this_val, \
                         int argc, LEPUSValueConst* argv)

#define RenderFatal(expression, ...) \
  LynxFatal(expression, LYNX_ERROR_CODE_DATA_BINDING, __VA_ARGS__)

#define CHECK_ARGC_EQ(name, count) \
  RenderFatal(argc == count, #name " params size should == " #count);

#define CHECK_ARGC_GE(name, count) \
  RenderFatal(argc >= count, #name " params size should == " #count);
void Utils::RegisterNGBuiltin(lepus::Context* context) {
  lepus::RegisterNGCFunction(context, kCFuncIndexOf, &IndexOf);
  lepus::RegisterNGCFunction(context, kCFuncGetLength, &GetLength);
  lepus::RegisterNGCFunction(context, kCFuncSetValueToMap, &SetValueToMap);
}

RENDERER_FUNCTION(SlotFunction) { return LEPUS_UNDEFINED; }

void Renderer::RegisterNGBuiltin(lepus::Context* context, ArchOption option) {
  switch (option) {
    case ArchOption::FIBER_ARCH:
      RegisterNGBuiltinForFiber(context);
      break;
    case ArchOption::AIR_ARCH:
      RegisterNGBuiltinForAir(context);
      break;
    default:
      RegisterNGBuiltinForRadon(context);
  }
}

void Renderer::RegisterNGBuiltinForRadon(lepus::Context* context) {
  lepus::RegisterNGCFunction(context, kCFuncCreatePage, &CreateVirtualPage);
  lepus::RegisterNGCFunction(context, kCFuncAttachPage, &AttachPage);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualComponent,
                             &CreateVirtualComponent);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualNode,
                             &CreateVirtualNode);
  lepus::RegisterNGCFunction(context, kCFuncAppendChild, &AppendChild);
  lepus::RegisterNGCFunction(context, kCFuncAppendSubTree, &AppendSubTree);
  lepus::RegisterNGCFunction(context, kCFuncCloneSubTree, &CloneSubTree);
  lepus::RegisterNGCFunction(context, kCFuncSetClassTo, &SetClassTo);
  lepus::RegisterNGCFunction(context, kCFuncSetStyleTo, &SetStyleTo);
  lepus::RegisterNGCFunction(context, kCFuncSetEventTo, SetEventTo);
  lepus::RegisterNGCFunction(context, kCFuncSetAttributeTo, SetAttributeTo);
  lepus::RegisterNGCFunction(context, kCFuncSetStaticClassTo,
                             &SetStaticClassTo);
  lepus::RegisterNGCFunction(context, kCFuncSetStaticStyleTo,
                             &SetStaticStyleTo);
  lepus::RegisterNGCFunction(context, kCFuncSetStaticAttributeTo,
                             &SetStaticAttrTo);
  lepus::RegisterNGCFunction(context, kCFuncSetDataSetTo, &SetDataSetTo);
  lepus::RegisterNGCFunction(context, kCFuncSetStaticEventTo,
                             &SetStaticEventTo);
  lepus::RegisterNGCFunction(context, kCFuncSetId, &SetId);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualSlot, &CreateSlot);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualPlug,
                             &CreateVirtualPlug);
  lepus::RegisterNGCFunction(context, kCFuncMarkComponentHasRenderer,
                             &MarkComponentHasRenderer);
  lepus::RegisterNGCFunction(context, kCFuncSetProp, &SetProp);
  lepus::RegisterNGCFunction(context, kCFuncSetData, &SetData);
  lepus::RegisterNGCFunction(context, kCFuncAddPlugToComponent,
                             AddVirtualPlugToComponent);
  lepus::RegisterNGCFunction(context, kCFuncAppendVirtualPlugToComponent,
                             AppendVirtualPlugToComponent);
  lepus::RegisterNGCFunction(context, kCFuncGetComponentData,
                             &GetComponentData);
  lepus::RegisterNGCFunction(context, kCFuncGetComponentProps,
                             &GetComponentProps);
  lepus::RegisterNGCFunction(context, kCFuncSetDynamicStyleTo,
                             &SetDynamicStyleTo);
  lepus::RegisterNGCFunction(context, kCFuncGetLazyLoadCount,
                             &ThemedTranslationLegacy);

  lepus::RegisterNGCFunction(context, kCFuncUpdateComponentInfo,
                             &UpdateComponentInfo);
  lepus::RegisterNGCFunction(context, kCFuncGetComponentInfo,
                             &GetComponentInfo);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualListNode,
                             &CreateVirtualListNode);
  lepus::RegisterNGCFunction(context, kCFuncAppendListComponentInfo,
                             &AppendListComponentInfo);
  lepus::RegisterNGCFunction(context, kCFuncSetListRefreshComponentInfo,
                             &SlotFunction);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualComponentByName,
                             &CreateComponentByName);
  lepus::RegisterNGCFunction(context, kCFuncCreateDynamicVirtualComponent,
                             &CreateDynamicVirtualComponent);
  lepus::RegisterNGCFunction(context, kCFuncRenderDynamicComponent,
                             &RenderDynamicComponent);
  lepus::RegisterNGCFunction(context, kCFuncThemedTranslation,
                             &ThemedTranslation);
  lepus::RegisterNGCFunction(context, kCFuncRegisterDataProcessor,
                             &RegisterDataProcessor);
  lepus::RegisterNGCFunction(context, kCFuncThemedLangTranslation,
                             &ThemedLanguageTranslation);

  lepus::RegisterNGCFunction(context, kCFuncGetComponentContextData,
                             &GetComponentContextData);
  lepus::RegisterNGCFunction(context, kCFuncProcessComponentData,
                             &ProcessComponentData);

  lepus::RegisterNGCFunction(context, kCFuncPushDynamicNode, &PushDynamicNode);
  lepus::RegisterNGCFunction(context, kCFuncGetDynamicNode, &GetDynamicNode);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonNode, &CreateRadonNode);
  lepus::RegisterNGCFunction(context, kCFuncAppendRadonChild,
                             &AppendRadonChild);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonPage, &CreateRadonPage);
  lepus::RegisterNGCFunction(context, kCFuncAttachRadonPage, &AttachRadonPage);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonAttributeTo,
                             SetRadonAttributeTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonStaticAttributeTo,
                             &SetStaticAttrTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonStyleTo, SetRadonStyleTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonStaticStyleTo,
                             &SetRadonStaticStyleTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonClassTo, SetRadonClassTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonStaticClassTo,
                             &SetRadonStaticClassTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonStaticEventTo,
                             &SetStaticEventTo);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonDataSetTo,
                             &UpdateRadonDataSet);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonId, SetRadonId);
  lepus::RegisterNGCFunction(context, kCFuncUpdateRadonId, &UpdateRadonId);
  lepus::RegisterNGCFunction(context, kCFuncCreateIfRadonNode,
                             &CreateIfRadonNode);
  lepus::RegisterNGCFunction(context, kCFuncUpdateIfNodeIndex,
                             &UpdateIfNodeIndex);
  lepus::RegisterNGCFunction(context, kCFuncRenderRadonComponentInLepus,
                             &RenderRadonComponentInLepus);
  lepus::RegisterNGCFunction(context, kCFuncCreateForRadonNode,
                             &CreateForRadonNode);
  lepus::RegisterNGCFunction(context, kCFuncUpdateForNodeItemCount,
                             &UpdateForNodeItemCount);
  lepus::RegisterNGCFunction(context, kCFuncGetForNodeChildWithIndex,
                             &GetForNodeChildWithIndex);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonComponent,
                             &CreateRadonComponent);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonComponentByName,
                             &CreateRadonComponentByName);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonDynamicComponent,
                             &CreateRadonDynamicComponent);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonProp, &SetProp);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonData, &SetData);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonSlot, &CreateSlot);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonPlug, &CreateRadonPlug);
  lepus::RegisterNGCFunction(context, kCFuncAddRadonPlugToComponent,
                             &AddRadonPlugToComponent);
  lepus::RegisterNGCFunction(context, kCFuncUpdateRadonComponentInLepus,
                             &UpdateRadonComponentInLepus);
  lepus::RegisterNGCFunction(context, kCFuncUpdateRadonDynamicComponentInLepus,
                             &UpdateRadonDynamicComponentInLepus);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonDynamicStyleTo,
                             SetRadonDynamicStyleTo);
  lepus::RegisterNGCFunction(context, kCFuncUpdateRadonComponentInfo,
                             &UpdateComponentInfo);
  lepus::RegisterNGCFunction(context, kCFuncGetRadonComponentInfo,
                             &GetComponentInfo);
  lepus::RegisterNGCFunction(context, kCFuncCreateListRadonNode,
                             &CreateListRadonNode);
  lepus::RegisterNGCFunction(context, kCFuncAppendRadonListComponentInfo,
                             &AppendRadonListComponentInfo);
  lepus::RegisterNGCFunction(context, kCFuncCreateRadonBlockNode,
                             &CreateRadonBlockNode);
  lepus::RegisterNGCFunction(context, kCFuncSetStaticStyleTo2,
                             &SetStaticStyleTo2);
  lepus::RegisterNGCFunction(context, kCFuncSetStaticStyleToByFiber,
                             &SetStaticStyleTo2);
  lepus::RegisterNGCFunction(context, kCFuncDidUpdateRadonList,
                             &DidUpdateRadonList);
  lepus::RegisterNGCFunction(context, kCFuncSetRadonStaticStyleToByFiber,
                             &SetRadonStaticStyleToByFiber);
  lepus::RegisterNGCFunction(context, kCFuncSetScriptEventTo,
                             &SetScriptEventTo);
  lepus::RegisterNGCFunction(context, kCFuncRegisterElementWorklet,
                             &RegisterElementWorklet);
  lepus::RegisterNGCFunction(context, kCFuncSetContextData, &SetContextData);
  lepus::RegisterNGCFunction(context, kCFuncCreateVirtualPlugWithComponent,
                             &CreateVirtualPlugWithComponent);
  lepus::RegisterNGCFunction(context, kCFuncAddEventListener,
                             &AddEventListener);
  lepus::RegisterNGCFunction(context, kCFuncI18nResourceTranslation,
                             &I18nResourceTranslation);
  lepus::RegisterNGCFunction(context, kCFuncReFlushPage, &ReFlushPage);
  lepus::RegisterNGCFunction(context, kCFuncSetComponent, &SetComponent);
  lepus::RegisterNGCFunction(context, kCFuncGetGlobalProps, &GetGlobalProps);
  lepus::RegisterNGCFunction(context, kCFuncHandleExceptionInLepus,
                             &HandleExceptionInLepus);
  lepus::RegisterNGCFunction(context, kCFuncMarkPageElement, &MarkPageElement);
  lepus::RegisterNGCFunction(context, kCFuncFilterI18nResource,
                             &FilterI18nResource);
  lepus::RegisterNGCFunction(context, kCFuncSendGlobalEvent, &SendGlobalEvent);
  lepus::RegisterNGCFunction(context, kCFunctionSetSourceMapRelease,
                             &SetSourceMapRelease);
  lepus::RegisterNGCFunction(context, kCFuncGetSystemInfo, &GetSystemInfo);
  lepus::RegisterNGCFunction(context, kCFuncAddFallbackToDynamicComponent,
                             &AddFallbackToDynamicComponent);
}

void Renderer::RegisterNGBuiltinForFiber(lepus::Context* context) {
  /* Element API BEGIN */
  lepus::RegisterNGCFunction(context, kCFunctionCreateElement,
                             &FiberCreateElement);
  lepus::RegisterNGCFunction(context, kCFunctionCreatePage, &FiberCreatePage);
  lepus::RegisterNGCFunction(context, kCFunctionCreateComponent,
                             &FiberCreateComponent);
  lepus::RegisterNGCFunction(context, kCFunctionCreateView, &FiberCreateView);
  lepus::RegisterNGCFunction(context, kCFunctionCreateList, &FiberCreateList);
  lepus::RegisterNGCFunction(context, kCFunctionCreateScrollView,
                             &FiberCreateScrollView);
  lepus::RegisterNGCFunction(context, kCFunctionCreateText, &FiberCreateText);
  lepus::RegisterNGCFunction(context, kCFunctionCreateImage, &FiberCreateImage);
  lepus::RegisterNGCFunction(context, kCFunctionCreateRawText,
                             &FiberCreateRawText);
  lepus::RegisterNGCFunction(context, kCFunctionCreateNonElement,
                             &FiberCreateNonElement);
  lepus::RegisterNGCFunction(context, kCFunctionCreateWrapperElement,
                             &FiberCreateWrapperElement);
  lepus::RegisterNGCFunction(context, kCFunctionAppendElement,
                             &FiberAppendElement);
  lepus::RegisterNGCFunction(context, kCFunctionRemoveElement,
                             &FiberRemoveElement);
  lepus::RegisterNGCFunction(context, kCFunctionInsertElementBefore,
                             &FiberInsertElementBefore);
  lepus::RegisterNGCFunction(context, kCFunctionFirstElement,
                             &FiberFirstElement);
  lepus::RegisterNGCFunction(context, kCFunctionLastElement, &FiberLastElement);
  lepus::RegisterNGCFunction(context, kCFunctionNextElement, &FiberNextElement);
  lepus::RegisterNGCFunction(context, kCFunctionReplaceElement,
                             &FiberReplaceElement);
  lepus::RegisterNGCFunction(context, kCFunctionReplaceElements,
                             &FiberReplaceElements);
  lepus::RegisterNGCFunction(context, kCFunctionSwapElement, &FiberSwapElement);
  lepus::RegisterNGCFunction(context, kCFunctionGetParent, &FiberGetParent);
  lepus::RegisterNGCFunction(context, kCFunctionGetChildren, &FiberGetChildren);
  lepus::RegisterNGCFunction(context, kCFunctionCloneElement,
                             &FiberCloneElement);
  lepus::RegisterNGCFunction(context, kCFunctionElementIsEqual,
                             &FiberElementIsEqual);
  lepus::RegisterNGCFunction(context, kCFunctionGetElementUniqueID,
                             &FiberGetElementUniqueID);
  lepus::RegisterNGCFunction(context, kCFunctionGetTag, &FiberGetTag);
  lepus::RegisterNGCFunction(context, kCFunctionSetAttribute,
                             &FiberSetAttribute);
  lepus::RegisterNGCFunction(context, kCFunctionGetAttributes,
                             &FiberGetAttributes);
  lepus::RegisterNGCFunction(context, kCFunctionAddClass, &FiberAddClass);
  lepus::RegisterNGCFunction(context, kCFunctionSetClasses, &FiberSetClasses);
  lepus::RegisterNGCFunction(context, kCFunctionGetClasses, &FiberGetClasses);
  lepus::RegisterNGCFunction(context, kCFunctionAddInlineStyle,
                             &FiberAddInlineStyle);
  lepus::RegisterNGCFunction(context, kCFunctionSetInlineStyles,
                             &FiberSetInlineStyles);
  lepus::RegisterNGCFunction(context, kCFunctionGetInlineStyles,
                             &FiberGetInlineStyles);
  lepus::RegisterNGCFunction(context, kCFunctionSetParsedStyles,
                             &FiberSetParsedStyles);
  lepus::RegisterNGCFunction(context, kCFunctionGetComputedStyles,
                             &FiberGetComputedStyles);
  lepus::RegisterNGCFunction(context, kCFunctionAddEvent, &FiberAddEvent);
  lepus::RegisterNGCFunction(context, kCFunctionSetEvents, &FiberSetEvents);
  lepus::RegisterNGCFunction(context, kCFunctionGetEvent, &FiberGetEvent);
  lepus::RegisterNGCFunction(context, kCFunctionGetEvents, &FiberGetEvents);
  lepus::RegisterNGCFunction(context, kCFunctionSetID, &FiberSetID);
  lepus::RegisterNGCFunction(context, kCFunctionGetID, &FiberGetID);
  lepus::RegisterNGCFunction(context, kCFunctionAddDataset, &FiberAddDataset);
  lepus::RegisterNGCFunction(context, kCFunctionSetDataset, &FiberSetDataset);
  lepus::RegisterNGCFunction(context, kCFunctionGetDataset, &FiberGetDataset);
  lepus::RegisterNGCFunction(context, kCFunctionGetDataByKey,
                             &FiberGetDataByKey);
  lepus::RegisterNGCFunction(context, kCFunctionGetComponentID,
                             &FiberGetComponentID);
  lepus::RegisterNGCFunction(context, kCFunctionUpdateComponentID,
                             &FiberUpdateComponentID);
  lepus::RegisterNGCFunction(context, kCFunctionUpdateListCallbacks,
                             &FiberUpdateListCallbacks);
  lepus::RegisterNGCFunction(context, kCFunctionFlushElementTree,
                             &FiberFlushElementTree);
  lepus::RegisterNGCFunction(context, kCFunctionOnLifecycleEvent,
                             &FiberOnLifecycleEvent);
  lepus::RegisterNGCFunction(context, kCFunctionElementFromBinary,
                             &FiberElementFromBinary);
  lepus::RegisterNGCFunction(context, kCFunctionElementFromBinaryAsync,
                             &FiberElementFromBinaryAsync);
  lepus::RegisterNGCFunction(context, kCFunctionQueryComponent,
                             &FiberQueryComponent);
  lepus::RegisterNGCFunction(context, kCFunctionSetSourceMapRelease,
                             &SetSourceMapRelease);
  lepus::RegisterNGCFunction(context, kCFunctionSetCSSId, &FiberSetCSSId);
  lepus::RegisterNGCFunction(context, kCFuncAddEventListener,
                             &AddEventListener);
  lepus::RegisterNGCFunction(context, kCFuncI18nResourceTranslation,
                             &I18nResourceTranslation);
  lepus::RegisterNGCFunction(context, kCFuncFilterI18nResource,
                             &FilterI18nResource);
  lepus::RegisterNGCFunction(context, kCFuncSendGlobalEvent, &SendGlobalEvent);
  lepus::RegisterNGCFunction(context, kCFunctionReportError, &ReportError);

  lepus::RegisterNGCFunction(context, kCFunctionQuerySelector,
                             &FiberQuerySelector);
  lepus::RegisterNGCFunction(context, kCFunctionQuerySelectorAll,
                             &FiberQuerySelectorAll);
  lepus::RegisterNGCFunction(context, kCFunctionSetLepusInitData,
                             &FiberSetLepusInitData);
  /* Element API END */
}

void Renderer::RegisterNGBuiltinForAir(lepus::Context* context) {
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateElement,
                             &AirCreateElement);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetElement, &AirGetElement);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreatePage, &AirCreatePage);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateComponent,
                             &AirCreateComponent);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateBlock,
                             &AirCreateBlock);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateIf, &AirCreateIf);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateRadonIf,
                             &AirCreateRadonIf);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateFor, &AirCreateFor);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreatePlug, &AirCreatePlug);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateSlot, &AirCreateSlot);
  lepus::RegisterNGCFunction(context, kCFunctionAirAppendElement,
                             &AirAppendElement);
  lepus::RegisterNGCFunction(context, kCFunctionAirRemoveElement,
                             &AirRemoveElement);
  lepus::RegisterNGCFunction(context, kCFunctionAirInsertElementBefore,
                             &AirInsertElementBefore);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetElementUniqueID,
                             &AirGetElementUniqueID);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetTag, &AirGetElementTag);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetAttribute,
                             &AirSetAttribute);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetInlineStyles,
                             &AirSetInlineStyles);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetEvent, &AirSetEvent);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetID, &AirSetID);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetElementByID,
                             &AirGetElementByID);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetElementByLepusID,
                             &AirGetElementByLepusID);
  lepus::RegisterNGCFunction(context, kCFunctionAirUpdateIfNodeIndex,
                             &AirUpdateIfNodeIndex);
  lepus::RegisterNGCFunction(context, kCFunctionAirUpdateForNodeIndex,
                             &AirUpdateForNodeIndex);
  lepus::RegisterNGCFunction(context, kCFunctionAirUpdateForChildCount,
                             &AirUpdateForChildCount);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetForNodeChildWithIndex,
                             &AirGetForNodeChildWithIndex);
  lepus::RegisterNGCFunction(context, kCFunctionAirPushForNode,
                             &AirPushForNode);
  lepus::RegisterNGCFunction(context, kCFunctionAirPopForNode, &AirPopForNode);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetChildElementByIndex,
                             &AirGetChildElementByIndex);
  lepus::RegisterNGCFunction(context, kCFunctionAirPushAirDynamicNode,
                             &AirPushDynamicNode);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetAirDynamicNode,
                             &AirGetDynamicNode);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetAirComponentProp,
                             &AirSetComponentProp);
  lepus::RegisterNGCFunction(context, kCFunctionAirRenderComponentInLepus,
                             &AirRenderComponentInLepus);
  lepus::RegisterNGCFunction(context, kCFunctionAirUpdateComponentInLepus,
                             &AirUpdateComponentInLepus);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetComponentInfo,
                             &AirGetComponentInfo);
  lepus::RegisterNGCFunction(context, kCFunctionAirUpdateComponentInfo,
                             &AirUpdateComponentInfo);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetData, &AirGetData);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetProps, &AirGetProps);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetData, &AirSetData);
  lepus::RegisterNGCFunction(context, kCFunctionAirFlushElement,
                             &AirFlushElement);
  lepus::RegisterNGCFunction(context, kCFunctionAirFlushElementTree,
                             &AirFlushElementTree);
  lepus::RegisterNGCFunction(context, kCFunctionTriggerLepusBridge,
                             &TriggerLepusBridge);
  lepus::RegisterNGCFunction(context, kCFunctionTriggerLepusBridgeSync,
                             &TriggerLepusBridgeSync);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetDataSet, &AirSetDataSet);
  lepus::RegisterNGCFunction(context, kCFunctionAirSendGlobalEvent,
                             &AirSendGlobalEvent);
  lepus::RegisterNGCFunction(context, kCFunctionSetTimeout, &SetTimeout);
  lepus::RegisterNGCFunction(context, kCFunctionClearTimeout, &ClearTimeout);
  lepus::RegisterNGCFunction(context, kCFunctionSetTimeInterval,
                             &SetTimeInterval);
  lepus::RegisterNGCFunction(context, kCFunctionClearTimeInterval,
                             &ClearTimeInterval);
  lepus::RegisterNGCFunction(context, kCFuncAddEventListener,
                             &AddEventListener);
  lepus::RegisterNGCFunction(context, kCFuncRegisterDataProcessor,
                             &RegisterDataProcessor);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetElementByUniqueID,
                             &AirGetElementByUniqueID);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetRootElement,
                             &AirGetRootElement);
  lepus::RegisterNGCFunction(context, kCFunctionRemoveEventListener,
                             &RemoveEventListener);
  lepus::RegisterNGCFunction(context, kCFunctionTriggerComponentEvent,
                             &TriggerComponentEvent);
  lepus::RegisterNGCFunction(context, kCFunctionAirCreateRawText,
                             &AirCreateRawText);
  lepus::RegisterNGCFunction(context, kCFunctionAirSetClasses, &AirSetClasses);
  lepus::RegisterNGCFunction(context, kCFunctionAirPushComponentNode,
                             &AirPushComponentNode);
  lepus::RegisterNGCFunction(context, kCFunctionAirPopComponentNode,
                             &AirPopComponentNode);
  lepus::RegisterNGCFunction(context, kCFunctionAirGetParentForNode,
                             &AirGetParentForNode);
  lepus::RegisterNGCFunction(context, kCFunctionReportError, &ReportError);
  lepus::RegisterNGCFunction(context, kCFunctionAirFlushTree, &AirFlushTree);
}

}  // namespace tasm
}  // namespace lynx
