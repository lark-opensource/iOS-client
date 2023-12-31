// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LYNX_TRACE_EVENT_H_
#define LYNX_TASM_LYNX_TRACE_EVENT_H_

constexpr char LYNX_TRACE_EVENT_VITALS_COLOR_ON_RUNTIME_READY[] = "#FD9927";
constexpr char LYNX_TRACE_EVENT_VITALS_COLOR_FIRST_MEANINGFUL_PAINT[] =
    "#0CCE6A";
constexpr char LYNX_TRACE_EVENT_VITALS_COLOR_START_LOAD[] = "#64b5f6";

constexpr char LYNX_TRACE_CATEGORY[] = "lynx";
constexpr char LYNX_TRACE_CATEGORY_VITALS[] = "vitals";
constexpr char LYNX_TRACE_CATEGORY_JAVASCRIPT[] = "javascript";
constexpr char LYNX_TRACE_CATEGORY_SCREENSHOTS[] =
    "disabled-by-default-devtools.screenshot";
constexpr char LYNX_TRACE_CATEGORY_FPS[] =
    "disabled-by-default-devtools.timeline.frame";
constexpr char LYNX_TRACE_CATEGORY_DEVTOOL_TIMELINE[] =
    "disabled-by-default-devtools.timeline";
constexpr char LYNX_TRACE_CATEGORY_JSB[] = "jsb";
constexpr char LYNX_TRACE_CATEGORY_ATRACE[] = "system";
constexpr char LYNX_TRACE_EVENT_START_LOAD[] = "StartLoad";
constexpr char LYNX_TRACE_EVENT_INTERNAL_DIFF[] = "LynxInternalDiff";
constexpr char LYNX_TRACE_EVENT_LOAD_TEMPLATE[] = "LynxLoadTemplate";
constexpr char LYNX_TRACE_EVENT_RELOAD_TEMPLATE[] = "LynxReloadTemplate";
constexpr char LYNX_TRACE_EVENT_RELOAD_TEMPLATE_WITH_GLOBAL_PROPS[] =
    "LynxReloadTemplateWithGlobalProps";
constexpr char LYNX_TRACE_EVENT_UPDATE_GLOBAL_PROPS[] = "LynxUpdateGlobalProps";
constexpr char LYNX_TRACE_EVENT_RELOAD_FROM_JS[] = "ReloadFromJS";
constexpr char LYNX_TRACE_EVENT_FROM_BINARY[] = "FromBinary";
constexpr char LYNX_TRACE_EVENT_DECODE[] = "LynxDecode";
constexpr char LYNX_TRACE_EVENT_VM_EXECUTE[] = "VMExecute";
constexpr char LYNX_TRACE_EVENT_UPDATE_DATA_BY_JS[] = "LynxUpdateDataByJS";
constexpr char LYNX_TRACE_EVENT_UPDATE_COMPONENT_DATA_BY_JS[] =
    "LynxUpdateComponentDataByJS";
constexpr char LYNX_TRACE_EVENT_FLUSH_DIFF[] = "LynxDiff";
constexpr char LYNX_TRACE_EVENT_FLUSH_DIFF_CONTENT[] = "LynxDiffContent";
constexpr char LYNX_TRACE_EVENT_FORCE_RENDER[] = "LynxForceRender";
constexpr char LYNX_TRACE_EVENT_DOM_READY[] = "LynxDomReady";
constexpr char LYNX_TRACE_EVENT_FORCE_FLUSH[] = "LynxForceFlush";
constexpr char LYNX_TRACE_EVENT_UPDATE_DATA[] = "LynxUpdateData";
constexpr char LYNX_TRACE_EVENT_LAYOUT[] = "LayoutContext.Layout";
constexpr char LYNX_TRACE_EVENT_BATCHED_UPDATE_DATA[] = "LynxBatchedUpdateData";
constexpr char LYNX_TRACE_EVENT_JS_UPDATE_COMPONENT_DATA[] =
    "LynxJSUpdateComponentData";
constexpr char LYNX_TRACE_EVENT_JS_BATCHED_UPDATE_DATA[] =
    "LynxJSBatchedUpdateData";
constexpr char LYNX_TRACE_EVENT_JS_APP_DATA_CHANGE[] = "LynxJSAppUpdateData";
constexpr char LYNX_TRACE_EVENT_DISPATCH_DRAW[] = "LynxDispatchDraw";
constexpr char LYNX_FIRE_TOUCH_EVENT[] = "FireTouchEvent";
constexpr char LYNX_TRACE_EVENT_DATA_PROCESSOR[] = "dataProcessor";

constexpr char LEPUS_EXECUTE[] = "Lepus.Execute";
constexpr char LEPUS_NG_EXECUTE[] = "LepusNG.Execute";
constexpr char LEPUS_NG_DESERIALIZE[] = "LepusNG.DeSerialize";
constexpr char LEPUS_NG_EVAL_BINARY[] = "LepusNG.EvalBinary";
constexpr char JS_AND_TASM_ALL_READY[] = "LynxJSTasmAllReady";
constexpr char JS_FINISH_LOAD_CORE[] = "LynxJSLoadCore";
constexpr char JS_CREATE_AND_LOAD_APP[] = "LynxCreateAndLoadApp";
constexpr char JS_LOAD_APP[] = "LoadJSApp";
constexpr char PATCH_VIRTUAL_NODE_ADD[] = "LynxPatchVirtualNodeAdded";
constexpr char ON_CREATE_UI[] = "LynxOnCreateUI";
constexpr char ON_INSERT_UI[] = "LynxOnInsertUI";

constexpr char CREATE_PAINT_NODE[] = "Catalyzer.CreatePaintingNode";
constexpr char UPDATE_PAINT_NODE[] = "Catalyzer.UpdatePaintingNode";
constexpr char CREATE_LAYOUT_NODE[] = "LayoutContext.CreateLayoutNode";
constexpr char UPDATE_LAYOUT_NODE[] = "LayoutContext.UpdateLayoutNode";
constexpr char INTERNAL_DIFF_CONTENT[] = "InternalDiffContent";
constexpr char UPDATE_PSEUDO_SHADOWS[] = "UpdatePseudoShadows";
constexpr char RESOLVE_ATTR_AND_STYLE[] = "ResolveAttributesAndStyle";

constexpr char SPREAD_VIRTUAL_NODE_WITHOUT_UI[] = "SpreadVirtualNodeWithoutUI";
constexpr char PATCH_VIRTUAL_NODE_REMOVED[] = "PatchVirtualNodeRemoved";
constexpr char NOTIFY_VIRTUAL_NODE_ADD[] = "NotifyVirtualNodeAdded";
constexpr char ELEMENT_SET_STYLE[] = "Element::SetStyle";
constexpr char ELEMENT_SET_STYLE_INTERNAL[] = "Element::SetStyleInternal";
constexpr char ELEMENT_FLUSH_PROPS[] = "Element.FlushProps";
constexpr char ELEMENT_UPDATE_DYNAMIC_CSS[] =
    "Element.PreparePropsBundleForDynamicCSS";
constexpr char UPDATE_LAYOUT_INTERNAL[] = "DoUpdateLayoutInternal";
constexpr char CALCULATE_LAYOUT[] = "CalculateLayout";
constexpr char LAYOUT_RECURSIVELY[] = "LayoutRecursively";
constexpr char ON_LAYOUT_AFTER[] = "OnLayoutAfter";
constexpr char ON_LAYOUT_FINISH[] = "OnLayoutFinish";
constexpr char FIRST_MEANINGFUL_PAINT[] = "FirstMeaningfulPaint";
constexpr char ON_RUNTIME_READY[] = "TimeToInteractive";
constexpr char UPDATE_LAYOUT_RECURSIVELY[] = "UpdateLayoutRecursively";
constexpr char ON_COMPONENT_ADD[] = "OnComponentAdded";
constexpr char ON_COMPONENT_REMOVE[] = "OnComponentRemoved";
constexpr char ON_COMPONENT_MOVE[] = "OnComponentMoved";
constexpr char CSS_PATCHING_GET_STYLE[] = "CSSPatching.GetStyle";
constexpr char INIT_PSEUDO_NOT_STYLE[] =
    "SharedCSSFragment::InitPseudoNotStyle";
constexpr char REPLACE_VARIABLE_BY_NEW_FRAGMENT[] =
    "SharedCSSFragment::ReplaceByNewFragment";
constexpr char CSS_PATCHING_APPLY_PSEUDO_STYLE[] =
    "CSSPatching.ApplyPseudoNotCSSStyle";
constexpr char CSS_PATCHING_APPLY_PSEUDO_CHILD[] =
    "CSSPatching.ApplyPseudoClassChildSelectorStyle";
constexpr char CSS_PATCHING_GET_CSS_BY_RULE[] = "CSSPatching.GetCSSByRule";
constexpr char CSS_PATCHING_HANDLE_CASCADE[] = "CSSPatching.handleCascade";
constexpr char CSS_GET_ATTRIBUTES[] = "CSSParserToken.GetAttribute";
constexpr char CSS_UNIT_HANDLER_PROCESSOR[] = "UnitHandler.Process";
constexpr char Z_INDEX_CHANGED[] = "ElementContainer::ZIndexChanged";
constexpr char FIND_PARENT_FOR_CHILD[] = "ElementContainer::FindParentForChild";
constexpr char FIND_PARENT_FOR_CHILD_AIR[] =
    "AirElementContainer::FindParentForChild";
constexpr char UPDATE_Z_INDEX_LIST[] = "ElementContainer::UpdateZIndexList";
constexpr char LYNX_TRACE_EVENT_SET_NATIVE_PROPS[] = "tasm::setNativeProps";
constexpr char ELEMENT_SET_NATIVE_PROPS[] = "Element::SetNativeProps";
constexpr char CATALYZER_TRIGGER_ON_NODE_READY[] =
    "Catalyzer::TriggerOnNodeReady";

// trace event for dynamic component.
constexpr char LYNX_TRACE_EVENT_REQUIRE_TEMPLATE_ENTRY[] =
    "DynamicComponent.RequireTemplateEntry";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_DERIVE_FROM_MODULE[] =
    "DynamicComponent.deriveFromMould";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_SET_CONTEXT[] =
    "DynamicComponent.setContext";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_PRELOAD[] =
    "DynamicComponent.Preload";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_DID_PRELOAD[] =
    "DynamicComponent.DidPreload";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_LOAD[] = "DynamicComponent.Load";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_DID_LOAD_COMPONENT[] =
    "DynamicComponent.DidLoadComponent";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_LOAD_COMPONENT[] =
    "DynamicComponent.LoadComponent";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_RENDER_ENTRANCE[] =
    "DynamicComponent.RenderEntrance";
constexpr char LYNX_TRACE_DYNAMIC_COMPONENT_BUILD_ENTRY[] =
    "DynamicComponent.BuildTemplateEntry";

constexpr char LYNX_TRACE_UI_OPERATION_QUEUE_CREATE_NODE_ENQUEUE_CRATE_VIEW[] =
    "UIOperationQueue.createNode.enqueueCreateView";
constexpr char LYNX_TRACE_UI_OPERATION_QUEUE_ASYNC_RENDER_FLUSH_WAIT_TASM[] =
    "UIOperationQueueAsyncRender.flush.waitTASM";
constexpr char LYNX_TRACE_UI_OPERATION_QUEUE_ASYNC_RENDER_FLUSH_WAIT_LAYOUT[] =
    "UIOperationQueueAsyncRender.flush.waitLayout";
constexpr char LYNX_TRACE_UI_OPERATION_QUEUE_ASYNC_RENDER_FLUSH[] =
    "UIOperationQueueAsyncRender.flush";

constexpr char LYNX_TRACE_DECODE_CSS_DESCRIPTOR[] = "DecodeCSSDescriptor";
constexpr char LYNX_TRACE_DECODE_CONTEXT[] = "DecodeContext";
constexpr char LYNX_TRACE_DECODE_PARSED_STYLES_SECTION[] =
    "DecodeParsedStylesSection";
constexpr char LYNX_TRACE_DECODE_ELEMENT_TEMPLATE_SECTION[] =
    "DecodeElementTemplateSection";
constexpr char LYNX_TRACE_DECODE_AIR_PARSED_STYLES_SECTION[] =
    "DecodeAirParsedStylesSection";
#endif  // LYNX_TASM_LYNX_TRACE_EVENT_H_
