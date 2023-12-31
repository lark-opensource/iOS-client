// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_DEBUG_ERROR_CODE_H_
#define LYNX_BASE_DEBUG_ERROR_CODE_H_

//!!!!! DO NOT MODIFY
//!!!!! See `tools/error_code/README.md`
#include <cstdint>

enum ErrCode : int32_t {
  // clang-format off
  // Section: Success 
  // Description:Success section

  // Error code for no error.
  LYNX_ERROR_CODE_SUCCESS = 0,

  // Section: Fatal Error 
  // Description:Fatal Error section, one should fallback or retry when encounter this error section.

  // Error occurred when loadTemplate, one should retry loadTemplate.
  LYNX_ERROR_CODE_LOAD_TEMPLATE = 100,
  // Error occurred when Layout, one should retry or fallback
  LYNX_ERROR_CODE_LAYOUT = 102,
  // Error occurred when fetch template resource.
  LYNX_ERROR_CODE_TEMPLATE_PROVIDER = 103,
  // Error occurred when find TemplateEntry. It indicates one use the Feature `Dynamic Components` but do not register specific components, See Error message for more infomation.
  LYNX_ERROR_CODE_RUNTIME_ENTRY = 104,
  // multi thread strategy can not support the List
  LYNX_ERROR_CODE_MULTI_THREAD_NOT_SUPPORT_LIST = 105,

  // Section: JavaScript 
  // Description:JavaScript related error.

  // Error occurred when executing JavaScript code. Check JavaScript call stack in error message for more information.
  LYNX_ERROR_CODE_JAVASCRIPT = 201,
  // Warning occurred when executing JavaScript code. Check JavaScript call stack in error message for more information.
  LYNX_ERROR_CODE_JS_WARNING = 202,

  // Section: Resource 
  // Description:Resource related error.

  // Error occurred when fetch resource. Check error message for more information.
  LYNX_ERROR_CODE_RESOURCE = 301,
  // Component name in the List Cell is not exist. You should check whether the name is wrong or the component is not registered.
  LYNX_ERROR_CODE_COMPONENT_NOT_EXIST = 302,

  // Section: Update 
  // Description:Error in update data pipeline.

  // Some unknown error in Update data pipeline. Check error message for more information.
  LYNX_ERROR_CODE_UPDATE = 401,
  // Input Parameter of Lepus Render function is not valid.
  LYNX_ERROR_CODE_DATA_BINDING = 402,
  // `element_` in `DynamicCSSStylesManager` is null.
  LYNX_ERROR_CODE_DOM = 403,
  // The parameter in `TemplateData#fromString()` is not a valid JSON string.
  LYNX_ERROR_CODE_PARSE_DATA = 404,

  // Section: Canvas 
  // Description:Error in lynx Canvas.

  // Error in Lynx Canvas.
  LYNX_ERROR_CODE_CANVAS = 501,

  // Section: Exception 
  // Description:Error in Java or Objc Logic.

  // Error in Java or Objc Logic.
  LYNX_ERROR_CODE_EXCEPTION = 601,

  // Section: BaseLib 
  // Description:Error in perf collector.

  // Error in perf collector.
  LYNX_ERROR_CODE_BASE_LIB = 701,

  // Section: Jni 
  // Description:Error in JNI call.

  // error in JNI call. Check the Java stacktrace in error message.
  LYNX_ERROR_CODE_JNI = 801,

  // Section: NativeModules 
  // Description:Error in NativeModules call. See issue: #1510

  // One called a module that do not be registered.
  LYNX_ERROR_CODE_MODULE_NOT_EXIST = 900,
  // One called a module function that do not be registered.
  LYNX_ERROR_CODE_MODULE_FUNC_NOT_EXIST = 901,
  // One called a module function with wrong arguments count.
  LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM = 902,
  // One called a module fuction with wrong argument type.
  LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_TYPE = 903,
  // The module function call encountered a exception. Check error message for exception stack trace.
  LYNX_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION = 904,
  // Module business error reported by module function implementation.
  LYNX_ERROR_CODE_MODULE_BUSINESS_ERROR = 905,
  // The promise module function parameter is not a function.
  LYNX_ERROR_CODE_MODULE_FUNC_PROMISE_ARG_NOT_FUNC = 906,
  // The promise module function parameter count is wrong.
  LYNX_ERROR_CODE_MODULE_FUNC_PROMISE_ARG_NUM_WRONG = 907,

  // Section: Event 
  // Description:Error in Lynx Event.

  // Error in Lynx Event.
  LYNX_ERROR_CODE_EVENT = 1001,

  // Section: Lepus 
  // Description:Error in Lepus.

  // Error in Lepus.
  LYNX_ERROR_CODE_LEPUS = 1101,

  // Section: MainFlow 
  // Description:Error in render main flow.

  // A place error code, which is not used.
  LYNX_ERROR_CODE_MAIN_FLOW = 1201,
  // LynxView is not destroyed in UI thread.
  LYNX_ERROR_CODE_LYNX_VIEW_DESTROY_NOT_ON_UI = 1202,
  // SyncFlush in a non-ui thread.
  LYNX_ERROR_CODE_SYNC_FLUSH_IN_NON_UI_THREAD = 1203,

  // Section: Css 
  // Description:Error in CSS module

  // Error in CSS module.
  LYNX_ERROR_CODE_CSS = 1301,

  // Section: Asset 
  // Description:Error in CSS related logic.

  // Error in CSS related logic.
  LYNX_ERROR_CODE_ASSET = 1401,

  // Section: Cli 
  // Description:Error in CSS related logic.

  // Error in CSS related logic.
  LYNX_ERROR_CODE_CLI = 1501,

  // Section: DynamicComponent 
  // Description:Error in dynamic component related logic.

  // failed when load a dynamic component. Check error message for component info.
  LYNX_ERROR_CODE_DYNAMIC_COMPONENT_LOAD_FAIL = 1601,
  // Load an empty dynamic component template data.
  LYNX_ERROR_CODE_DYNAMIC_COMPONENT_FILE_EMPTY = 1602,
  // The dynamic component template data cannot be decoded.
  LYNX_ERROR_CODE_DYNAMIC_COMPONENT_DECODE_FAIL = 1603,

  // Section: ExternalSource 
  // Description:Error in load external source.

  // Error in load external source.
  LYNX_ERROR_CODE_EXTERNAL_SOURCE = 1701,

  // Section: EventException 
  // Description:Error for event.

  // Error for event.
  LYNX_ERROR_CODE_EVENT_EXCEPTION = 1801,

  // Section: ElementWorklet 
  // Description:Error for element worklet

  // Error for lepus call exception.
  LYNX_ERROR_CODE_LEPUS_CALL_EXCEPTION = 1901,
  // Error for raf call exception.
  LYNX_ERROR_CODE_RAF_CALL_EXCEPTION = 1902,
  // Error for worklet module exception
  LYNX_ERROR_CODE_WORKLET_MODULE_EXCEPTION = 1903,

  // Section: LepusMethod 
  // Description:Error for lepus methods

  // Lepus method call success.
  LYNX_ERROR_CODE_LEPUS_SUCCESS = 2000,
  // Lepus Module do not exist.
  LYNX_ERROR_CODE_LEPUS_MODULE_NOT_EXIST = 2001,
  // Lepus module function do not exist.
  LYNX_ERROR_CODE_LEPUS_MODULE_FUNC_NOT_EXIST = 2002,
  // Lepus module function called with wrong arguments number.
  LYNX_ERROR_CODE_LEPUS_MODULE_FUNC_WRONG_ARG_NUM = 2003,
  // Lepus module function called with wrong argument type.
  LYNX_ERROR_CODE_LEPUS_MODULE_FUNC_WRONG_ARG_TYPE = 2004,
  // Lepus module function executed with exception.
  LYNX_ERROR_CODE_LEPUS_MODULE_FUNC_CALL_EXCEPTION = 2005,
  // Lepus Module bussiness error reported by module function implementation.
  LYNX_ERROR_CODE_LEPUS_MODULE_BUSSINESS_ERROR = 2006,
  // Lepus Module argument error.
  LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR = 2007,

  // Section: ImageResource 
  // Description:Error for image resources.

  // Error for unexpected big image.
  LYNX_ERROR_CODE_BIG_IMAGE = 2100,
  // Error for image resource provider.
  LYNX_ERROR_CODE_PIC_SOURCE = 2101,
  // Error for FE design or user settings.
  LYNX_ERROR_CODE_FROM_USER_OR_DESIGN = 2102,
  // Error for net error or others.
  LYNX_ERROR_CODE_FROM_T_T_NET_OR_OTHERS = 2199,

  // Section: HMR 
  // Description:Error for HMR.

  // Error for HMR Lepus update.
  LYNX_ERROR_CODE_HMR_LEPUS_UPDATE = 3000,

  // Section: Binary 
  // Description:Error for encode template binary.

  // Error for encode template binary.
  LYNX_ERROR_CODE_BINARY = 9901,

  // Section: SSR 
  // Description:Error for rendering page whose dom is constructed on server side.

  // Fail SSR data to decode ssr data. Data is likely corrupted.
  LYNX_ERROR_CODE_SSR_DECODE = 10001,
  // Error occurred when loadSSRData.
  LYNX_ERROR_CODE_LOAD_SSR_DATA = 10002,
  // Load SSR data with a higher API version than the version the sdk is supported.
  LYNX_ERROR_CODE_API_VERSION_NOT_SUPPORTED = 10003,
  // The dom structure after hydration deviates from the SSR result, may caused by the difference of injected global data or template used for SSR and hydrate.
  LYNX_ERROR_CODE_HYDRATE_RESULT_DEVIATE_FROM_SSR_RESULT = 10004,

  // Section: LynxResourceModule 
  // Description:Error for prefetching resource from JS.

  // Parameter error.
  LYNX_ERROR_CODE_RES_MODULE_PARAMS_ERROR = 11001,
  // Imager prefetch helper not exist.
  LYNX_ERROR_CODE_RES_MODULE_IMG_PREFETCH_HELPER_NOT_EXIST = 11002,
  // Resource service not exist.
  LYNX_ERROR_CODE_RES_MODULE_RESOURCE_SERVICE_NOT_EXIST = 11003,

  // clang-format on
};

//!!!!! DO NOT MODIFY
//!!!!! See `tools/error_code/README.md`

#endif  // LYNX_BASE_DEBUG_ERROR_CODE_H_
