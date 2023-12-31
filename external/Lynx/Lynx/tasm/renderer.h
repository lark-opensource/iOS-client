// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RENDERER_H_
#define LYNX_TASM_RENDERER_H_

#include "tasm/compile_options.h"

namespace lynx {

namespace lepus {
class Context;
}

namespace tasm {

static const char* kCFuncGetLength = "_GetLength";
static const char* kCFuncIndexOf = "_IndexOf";
static const char* kCFuncSetValueToMap = "_SetValueToMap";

static const char* kCFuncAttachPage = "_AttachPage";
static const char* kCFuncAppendChild = "_AppendChild";
static const char* kCFuncAppendSubTree = "_AppendSubTree";
static const char* kCFuncCloneSubTree = "_CloneSubTree";
static const char* kCFuncCreateVirtualNode = "_CreateVirtualNode";
static const char* kCFuncCreateVirtualComponent = "_CreateVirtualComponent";
static const char* kCFuncCreatePage = "_CreatePage";
static const char* kCFuncSetAttributeTo = "_SetAttributeTo";
static const char* kCFuncSetStaticAttributeTo = "_SetStaticAttributeTo";
static const char* kCFuncSetStyleTo = "_SetStyleTo";
static const char* kCFuncSetStaticStyleTo = "_SetStaticStyleTo";
static const char* kCFuncSetDynamicStyleTo = "_SetDynamicStyleTo";
static const char* kCFuncSetClassTo = "_SetClassTo";
static const char* kCFuncSetStaticClassTo = "_SetStaticClassTo";
static const char* kCFuncSetStaticEventTo = "_SetStaticEventTo";
static const char* kCFuncSetDataSetTo = "_SetDataSetTo";
static const char* kCFuncSetEventTo = "_SetEventTo";
static const char* kCFuncSetId = "_SetId";
static const char* kCFuncSetStaticStyleTo2 = "_SetStaticStyleTo2";
static const char* kCFuncSetStaticStyleToByFiber = "_SetStaticStyleToByFiber";
static const char* kCFuncGetGlobalProps = "_GetGlobalProps";
static const char* kCFuncHandleExceptionInLepus = "_HandleExceptionInLepus";
static const char* kCFuncMarkPageElement = "_MarkPageElement";
static const char* kCFuncGetSystemInfo = "_GetSystemInfo";

// Set Element Worklet
constexpr static const char* kCFuncSetScriptEventTo = "_SetScriptEventTo";

static const char* kCFuncCreateVirtualSlot = "_CreateVirtualSlot";
static const char* kCFuncCreateVirtualPlug = "_CreateVirtualPlug";
static const char* kCFuncCreateVirtualPlugWithComponent =
    "_CreateVirtualPlugWithComponent";
static const char* kCFuncMarkComponentHasRenderer = "_MarkComponentHasRenderer";

// Relevant to component
static const char* kCFuncSetProp = "_SetProp";
static const char* kCFuncSetData = "_SetData";
static const char* kCFuncProcessComponentData = "_ProcessData";
static const char* kCFuncAddPlugToComponent = "_AddPlugToComponent";
static const char* kCFuncAppendVirtualPlugToComponent =
    "_AppendPlugToComponent";
static const char* kCFuncGetComponentData = "_GetComponentData";
static const char* kCFuncGetComponentProps = "_GetComponentProps";
static const char* kCFuncUpdateComponentInfo = "_UpdateComponentInfo";
static const char* kCFuncGetComponentInfo = "_GetComponentInfo";
static const char* kCFuncCreateVirtualListNode = "_CreateVirtualListNode";
static const char* kCFuncAppendListComponentInfo = "_AppendListComponentInfo";
static const char* kCFuncSetListRefreshComponentInfo =
    "_SetListRefreshComponentInfo";
static const char* kCFuncCreateVirtualComponentByName =
    "_CreateVirtualComponentByName";
static const char* kCFuncCreateDynamicVirtualComponent =
    "_CreateDynamicVirtualComponent";
static const char* kCFuncRenderDynamicComponent = "_RenderDynamicComponent";
static const char* kCFuncAddFallbackToDynamicComponent =
    "_AddFallbackToDynamicComponent";
static const char* kCFuncSetComponent = "_SetComponent";

static const char* kCFuncGetLazyLoadCount = "_GetLazyLoadCount";
static const char* kCFuncThemedTranslation = "_sysTheme";
static const char* kCFuncThemedLangTranslation = "_sysLang";

// Template API
static const char* kCFuncRegisterDataProcessor = "registerDataProcessor";
static const char* kCFuncAddEventListener = "_AddEventListener";
static const char* kCFuncSendGlobalEvent = "_SendGlobalEvent";

// Element Worklet
constexpr static const char* kCFuncRegisterElementWorklet =
    "registerElementWorklet";

static const char* kCFuncPushDynamicNode = "_PushDynamicNode";
static const char* kCFuncGetDynamicNode = "_GetDynamicNode";
static const char* kCFuncCreateRadonNode = "_CreateRadonNode";
static const char* kCFuncAppendRadonChild = "_AppendRadonChild";
static const char* kCFuncCreateRadonPage = "_CreateRadonPage";
static const char* kCFuncAttachRadonPage = "_AttachRadonPage";

static const char* kCFuncSetRadonAttributeTo = "_SetRadonAttributeTo";
static const char* kCFuncSetRadonStaticAttributeTo =
    "_SetRadonStaticAttributeTo";
static const char* kCFuncSetRadonStyleTo = "_SetRadonStyleTo";
static const char* kCFuncSetRadonStaticStyleTo = "_SetRadonStaticStyleTo";
static const char* kCFuncSetRadonDynamicStyleTo = "_SetRadonDynamicStyleTo";
static const char* kCFuncSetRadonClassTo = "_SetRadonClassTo";
static const char* kCFuncSetRadonStaticClassTo = "_SetRadonStaticClassTo";
static const char* kCFuncSetRadonStaticEventTo = "_SetRadonStaticEventTo";
static const char* kCFuncSetRadonDataSetTo = "_SetRadonDataSetTo";
static const char* kCFuncSetRadonEventTo = "_SetRadonEventTo";
static const char* kCFuncSetRadonId = "_SetRadonId";
static const char* kCFuncUpdateRadonId = "_UpdateRadonId";
static const char* kCFuncCreateIfRadonNode = "_CreateIfRadonNode";
static const char* kCFuncUpdateIfNodeIndex = "_UpdateIfNodeIndex";
static const char* kCFuncCreateForRadonNode = "_CreateForRadonNode";
static const char* kCFuncUpdateForNodeItemCount = "_UpdateForNodeItemCount";
static const char* kCFuncGetForNodeChildWithIndex = "_GetForNodeChildWithIndex";
static const char* kCFuncSetRadonStaticStyleToByFiber =
    "_SetRadonStaticStyleToByFiber";

// i18n
static const char* kCFuncFilterI18nResource = "_FilterI18nResource";
static const char* kCFuncI18nResourceTranslation = "_I18nResourceTranslation";
static const char* kCFuncReFlushPage = "_ReFlushPage";

// Radon Component
static const char* kCFuncCreateRadonComponent = "_CreateRadonComponent";
static const char* kCFuncCreateRadonComponentByName =
    "_CreateRadonComponentByName";
static const char* kCFuncCreateRadonDynamicComponent =
    "_CreateRadonDynamicComponent";
static const char* kCFuncSetRadonData = "_SetRadonData";
static const char* kCFuncSetRadonProp = "_SetRadonProp";
static const char* kCFuncCreateRadonSlot = "_CreateRadonSlot";
static const char* kCFuncCreateRadonPlug = "_CreateRadonPlug";
static const char* kCFuncAddRadonPlugToComponent = "_AddRadonPlugToComponent";
static const char* kCFuncRemoveRadonPlugFromComponent =
    "_RemoveRadonPlugFromComponent";
static const char* kCFuncGetComponentContextData = "_context";
static const char* kCFuncSetContextData = "_SetContextData";

// Radon List
static const char* kCFuncCreateListRadonNode = "_CreateListRadonNode";
static const char* kCFuncAppendRadonListComponentInfo =
    "_AppendRadonListComponentInfo";
static const char* kCFuncUpdateRadonComponentInfo = "_UpdateRadonComponentInfo";
static const char* kCFuncGetRadonComponentInfo = "_GetRadonComponentInfo";
static const char* kCFuncCreateRadonBlockNode = "_CreateRadonBlockNode";
static const char* kCFuncRenderRadonComponentInLepus =
    "_RenderRadonComponentInLepus";
static const char* kCFuncUpdateRadonComponentInLepus =
    "_UpdateRadonComponentInLepus";
static const char* kCFuncUpdateRadonDynamicComponentInLepus =
    "_UpdateRadonDynamicComponentInLepus";
static const char* kCFuncDidUpdateRadonList = "_DidUpdateRadonList";

// Element API
// Create Element
static const char* kCFunctionCreateElement = "__CreateElement";
static const char* kCFunctionCreateView = "__CreateView";
static const char* kCFunctionCreateText = "__CreateText";
static const char* kCFunctionCreateImage = "__CreateImage";
static const char* kCFunctionCreateRawText = "__CreateRawText";
static const char* kCFunctionCreateNonElement = "__CreateNonElement";
static const char* kCFunctionCreateWrapperElement = "__CreateWrapperElement";
static const char* kCFunctionCreateList = "__CreateList";
static const char* kCFunctionCreateScrollView = "__CreateScrollView";
static const char* kCFunctionCreatePage = "__CreatePage";
static const char* kCFunctionCreateComponent = "__CreateComponent";
static const char* kCFunctionQuerySelector = "__QuerySelector";
static const char* kCFunctionQuerySelectorAll = "__QuerySelectorAll";
// Element Tree
static const char* kCFunctionAppendElement = "__AppendElement";
static const char* kCFunctionRemoveElement = "__RemoveElement";
static const char* kCFunctionInsertElementBefore = "__InsertElementBefore";
static const char* kCFunctionFirstElement = "__FirstElement";
static const char* kCFunctionLastElement = "__LastElement";
static const char* kCFunctionNextElement = "__NextElement";
static const char* kCFunctionReplaceElement = "__ReplaceElement";
static const char* kCFunctionReplaceElements = "__ReplaceElements";
static const char* kCFunctionSwapElement = "__SwapElement";
static const char* kCFunctionGetParent = "__GetParent";
static const char* kCFunctionGetChildren = "__GetChildren";
static const char* kCFunctionCloneElement = "__CloneElement";
static const char* kCFunctionElementIsEqual = "__ElementIsEqual";
// Element Info
static const char* kCFunctionGetElementUniqueID = "__GetElementUniqueID";
static const char* kCFunctionGetTag = "__GetTag";
static const char* kCFunctionSetAttribute = "__SetAttribute";
static const char* kCFunctionGetAttributes = "__GetAttributes";
static const char* kCFunctionAddClass = "__AddClass";
static const char* kCFunctionSetClasses = "__SetClasses";
static const char* kCFunctionGetClasses = "__GetClasses";
static const char* kCFunctionAddInlineStyle = "__AddInlineStyle";
static const char* kCFunctionSetInlineStyles = "__SetInlineStyles";
static const char* kCFunctionGetInlineStyles = "__GetInlineStyles";
static const char* kCFunctionSetParsedStyles = "__SetParsedStyles";
static const char* kCFunctionGetComputedStyles = "__GetComputedStyles";
static const char* kCFunctionAddEvent = "__AddEvent";
static const char* kCFunctionSetEvents = "__SetEvents";
static const char* kCFunctionGetEvent = "__GetEvent";
static const char* kCFunctionGetEvents = "__GetEvents";
static const char* kCFunctionSetID = "__SetID";
static const char* kCFunctionGetID = "__GetID";
static const char* kCFunctionAddDataset = "__AddDataset";
static const char* kCFunctionSetDataset = "__SetDataset";
static const char* kCFunctionGetDataset = "__GetDataset";
static const char* kCFunctionGetDataByKey = "__GetDataByKey";
static const char* kCFunctionSetCSSId = "__SetCSSId";
// Element Component Info
static const char* kCFunctionGetComponentID = "__GetComponentID";
static const char* kCFunctionUpdateComponentID = "__UpdateComponentID";
// List Info
static const char* kCFunctionUpdateListCallbacks = "__UpdateListCallbacks";
// Other RenderFunctions
static const char* kCFunctionFlushElementTree = "__FlushElementTree";
static const char* kCFunctionOnLifecycleEvent = "__OnLifecycleEvent";
static const char* kCFunctionElementFromBinary = "__ElementFromBinary";
static const char* kCFunctionElementFromBinaryAsync =
    "__ElementFromBinaryAsync";
static const char* kCFunctionQueryComponent = "__QueryComponent";
static const char* kCFunctionSetLepusInitData = "__SetLepusInitData";

// air strict mode
// Create Element
static const char* kCFunctionAirCreateElement = "__AirCreateElement";
static const char* kCFunctionAirGetElement = "__AirGetElement";
static const char* kCFunctionAirCreatePage = "__AirCreatePage";
static const char* kCFunctionAirCreateComponent = "__AirCreateComponent";
static const char* kCFunctionAirCreateBlock = "__AirCreateBlock";
static const char* kCFunctionAirCreateIf = "__AirCreateIf";
static const char* kCFunctionAirCreateRadonIf = "__AirCreateRadonIf";
static const char* kCFunctionAirCreateFor = "__AirCreateFor";
static const char* kCFunctionAirCreatePlug = "__AirCreatePlug";
static const char* kCFunctionAirCreateSlot = "__AirCreateSlot";
// Element Tree
static const char* kCFunctionAirAppendElement = "__AirAppendElement";
static const char* kCFunctionAirRemoveElement = "__AirRemoveElement";
static const char* kCFunctionAirInsertElementBefore =
    "__AirInsertElementBefore";
// Element SetAttribute
static const char* kCFunctionAirGetElementUniqueID = "__AirGetElementUniqueID";
static const char* kCFunctionAirGetTag = "__AirGetTag";
static const char* kCFunctionAirSetAttribute = "__AirSetAttribute";
static const char* kCFunctionAirGetAttributes = "__AirGetAttributes";
static const char* kCFunctionAirSetInlineStyles = "__AirSetInlineStyles";
static const char* kCFunctionAirSetEvent = "__AirSetEvent";
static const char* kCFunctionAirSetID = "__AirSetID";

static const char* kCFunctionAirGetElementByID = "__AirGetElementById";
static const char* kCFunctionAirGetElementByUniqueID =
    "__AirGetElementByUniqueID";
static const char* kCFunctionAirGetElementByLepusID =
    "__AirGetElementByLepusID";
static const char* kCFunctionAirGetRootElement = "__AirGetRootElement";
static const char* kCFunctionAirGetParentForNode = "__AirGetParentForNode";

static const char* kCFunctionAirUpdateIfNodeIndex = "__AirUpdateIfNodeIndex";
static const char* kCFunctionAirUpdateForNodeIndex = "__AirUpdateForNodeIndex";
static const char* kCFunctionAirUpdateForChildCount =
    "__AirUpdateForChildCount";
static const char* kCFunctionAirGetForNodeChildWithIndex =
    "__AirGetForNodeChildWithIndex";
static const char* kCFunctionAirPushForNode = "__AirPushForNode";
static const char* kCFunctionAirPopForNode = "__AirPopForNode";
static const char* kCFunctionAirPushComponentNode = "__AirPushComponentNode";
static const char* kCFunctionAirPopComponentNode = "__AirPopComponentNode";
static const char* kCFunctionAirGetChildElementByIndex =
    "__AirGetChildElementByIndex";
static const char* kCFunctionAirPushAirDynamicNode = "__AirPushDynamicNode";
static const char* kCFunctionAirGetAirDynamicNode = "__AirGetDynamicNode";
static const char* kCFunctionAirSetAirComponentProp = "__AirSetComponentProp";
static const char* kCFunctionAirRenderComponentInLepus =
    "__AirRenderComponentInLepus";
static const char* kCFunctionAirUpdateComponentInLepus =
    "__AirUpdateComponentInLepus";
static const char* kCFunctionAirGetComponentInfo = "__AirGetComponentInfo";
static const char* kCFunctionAirUpdateComponentInfo =
    "__AirUpdateComponentInfo";
static const char* kCFunctionAirGetData = "__AirGetData";
static const char* kCFunctionAirGetProps = "__AirGetProps";
static const char* kCFunctionAirSetData = "__AirSetData";
static const char* kCFunctionAirFlushElement = "__AirFlushElement";
static const char* kCFunctionAirFlushElementTree = "__AirFlushElementTree";
static const char* kCFunctionAirFlushTree = "__AirFlushTree";
static const char* kCFunctionTriggerLepusBridge = "_TriggerLepusBridge";
static const char* kCFunctionTriggerLepusBridgeSync = "_TriggerLepusBridgeSync";
static const char* kCFunctionAirSetDataSet = "__AirSetDataSet";
static const char* kCFunctionAirSendGlobalEvent = "__AirSendGlobalEvent";
static const char* kCFunctionSetTimeout = "_SetTimeout";
static const char* kCFunctionClearTimeout = "_ClearTimeout";
static const char* kCFunctionSetTimeInterval = "_SetTimeInterval";
static const char* kCFunctionClearTimeInterval = "_ClearTimeInterval";
static const char* kCFunctionRemoveEventListener = "_RemoveEventListener";
static const char* kCFunctionTriggerComponentEvent = "_TriggerComponentEvent";
static const char* kCFunctionAirCreateRawText = "__AirCreateRawText";
static const char* kCFunctionAirSetClasses = "__AirSetClasses";

// lepusNg sourceMap
static const char* kCFunctionSetSourceMapRelease = "_SetSourceMapRelease";
static const char* kCFunctionReportError = "_ReportError";

class Utils {
 public:
  static void RegisterBuiltin(lepus::Context* context);
  static void RegisterNGBuiltin(lepus::Context* context);
};

class Renderer {
 public:
  static void RegisterBuiltin(lepus::Context* context, ArchOption option);
  static void RegisterNGBuiltin(lepus::Context* context, ArchOption option);

 private:
  static void RegisterBuiltinForRadon(lepus::Context* context);
  static void RegisterBuiltinForFiber(lepus::Context* context);
  static void RegisterBuiltinForAir(lepus::Context* context);
  static void RegisterNGBuiltinForRadon(lepus::Context* context);
  static void RegisterNGBuiltinForFiber(lepus::Context* context);
  static void RegisterNGBuiltinForAir(lepus::Context* context);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RENDERER_H_
