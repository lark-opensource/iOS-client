// Copyright 2022 The Lynx Authors. All rights reserved.

//!!!!! DO NOT MODIFY
//!!!!! See `tools/error_code/README.md`
// clang-format off

#import "LynxErrorCode.h"
#pragma mark - Section: Success
// Success section

// Error code for no error.
NSInteger const LynxErrorCodeSuccess = 0;

#pragma mark - Section: Fatal Error
// Fatal Error section, one should fallback or retry when encounter this error section.

// Error occurred when loadTemplate, one should retry loadTemplate.
NSInteger const LynxErrorCodeLoadTemplate = 100;
// Error occurred when Layout, one should retry or fallback
NSInteger const LynxErrorCodeLayout = 102;
// Error occurred when fetch template resource.
NSInteger const LynxErrorCodeTemplateProvider = 103;
// Error occurred when find TemplateEntry. It indicates one use the Feature `Dynamic Components` but do not register specific components, See Error message for more infomation.
NSInteger const LynxErrorCodeRuntimeEntry = 104;
// multi thread strategy can not support the List
NSInteger const LynxErrorCodeMultiThreadNotSupportList = 105;

#pragma mark - Section: JavaScript
// JavaScript related error.

// Error occurred when executing JavaScript code. Check JavaScript call stack in error message for more information.
NSInteger const LynxErrorCodeJavaScript = 201;
// Warning occurred when executing JavaScript code. Check JavaScript call stack in error message for more information.
NSInteger const LynxErrorCodeJsWarning = 202;

#pragma mark - Section: Resource
// Resource related error.

// Error occurred when fetch resource. Check error message for more information.
NSInteger const LynxErrorCodeForResourceError = 301;
// Component name in the List Cell is not exist. You should check whether the name is wrong or the component is not registered.
NSInteger const LynxErrorCodeComponentNotExist = 302;

#pragma mark - Section: Update
// Error in update data pipeline.

// Some unknown error in Update data pipeline. Check error message for more information.
NSInteger const LynxErrorCodeUpdate = 401;
// Input Parameter of Lepus Render function is not valid.
NSInteger const LynxErrorCodeDataBinding = 402;
// `element_` in `DynamicCSSStylesManager` is null.
NSInteger const LynxErrorCodeDom = 403;
// The parameter in `TemplateData#fromString()` is not a valid JSON string.
NSInteger const LynxErrorCodeParseData = 404;

#pragma mark - Section: Canvas
// Error in lynx Canvas.

// Error in Lynx Canvas.
NSInteger const LynxErrorCodeCanvas = 501;

#pragma mark - Section: Exception
// Error in Java or Objc Logic.

// Error in Java or Objc Logic.
NSInteger const LynxErrorCodeException = 601;

#pragma mark - Section: BaseLib
// Error in perf collector.

// Error in perf collector.
NSInteger const LynxErrorCodeBaseLib = 701;

#pragma mark - Section: Jni
// Error in JNI call.

// error in JNI call. Check the Java stacktrace in error message.
NSInteger const LynxErrorCodeJni = 801;

#pragma mark - Section: NativeModules
// Error in NativeModules call. See issue: #1510

// One called a module that do not be registered.
NSInteger const LynxErrorCodeModuleNotExist = 900;
// One called a module function that do not be registered.
NSInteger const LynxErrorCodeModuleFuncNotExist = 901;
// One called a module function with wrong arguments count.
NSInteger const LynxErrorCodeModuleFunWrongArgNum = 902;
// One called a module fuction with wrong argument type.
NSInteger const LynxErrorCodeModuleFuncWrongArgType = 903;
// The module function call encountered a exception. Check error message for exception stack trace.
NSInteger const LynxErrorCodeModuleFuncCallException = 904;
// Module business error reported by module function implementation.
NSInteger const LynxErrorCodeModuleBusinessError = 905;
// The promise module function parameter is not a function.
NSInteger const LynxErrorCodeModuleFuncPromiseArgNotFunc = 906;
// The promise module function parameter count is wrong.
NSInteger const LynxErrorCodeModuleFuncPromiseArgNumWrong = 907;

#pragma mark - Section: Event
// Error in Lynx Event.

// Error in Lynx Event.
NSInteger const LynxErrorCodeEvent = 1001;

#pragma mark - Section: Lepus
// Error in Lepus.

// Error in Lepus.
NSInteger const LynxErrorCodeLepus = 1101;

#pragma mark - Section: MainFlow
// Error in render main flow.

// A place error code, which is not used.
NSInteger const LynxErrorCodeMainFlow = 1201;
// LynxView is not destroyed in UI thread.
NSInteger const LynxErrorCodeLynxViewDestroyNotOnUi = 1202;
// SyncFlush in a non-ui thread.
NSInteger const LynxErrorCodeSyncFlushInNonUiThread = 1203;

#pragma mark - Section: Css
// Error in CSS module

// Error in CSS module.
NSInteger const LynxErrorCodeCSS = 1301;

#pragma mark - Section: Asset
// Error in CSS related logic.

// Error in CSS related logic.
NSInteger const LynxErrorCodeAsset = 1401;

#pragma mark - Section: Cli
// Error in CSS related logic.

// Error in CSS related logic.
NSInteger const LynxErrorCodeCli = 1501;

#pragma mark - Section: DynamicComponent
// Error in dynamic component related logic.

// failed when load a dynamic component. Check error message for component info.
NSInteger const LynxErrorDynamicComponentLoadFail = 1601;
// Load an empty dynamic component template data.
NSInteger const LynxErrorDynamicComponentFileEmpty = 1602;
// The dynamic component template data cannot be decoded.
NSInteger const LynxErrorDynamicComponentDecodeFail = 1603;

#pragma mark - Section: ExternalSource
// Error in load external source.

// Error in load external source.
NSInteger const LynxErrorCodeExternalSource = 1701;

#pragma mark - Section: EventException
// Error for event.

// Error for event.
NSInteger const LynxErrorCodeEventException = 1801;

#pragma mark - Section: ElementWorklet
// Error for element worklet

// Error for lepus call exception.
NSInteger const LynxErrorCodeLepusCallException = 1901;
// Error for raf call exception.
NSInteger const LynxErrorCodeRafCallException = 1902;
// Error for worklet module exception
NSInteger const LynxErrorCodeWorkletModuleException = 1903;

#pragma mark - Section: LepusMethod
// Error for lepus methods

// Lepus method call success.
NSInteger const LynxErrorCodeLepusSuccess = 2000;
// Lepus Module do not exist.
NSInteger const LynxErrorCodeLepusModuleNotExist = 2001;
// Lepus module function do not exist.
NSInteger const LynxErrorCodeLepusModuleFuncNotExist = 2002;
// Lepus module function called with wrong arguments number.
NSInteger const LynxErrorCodeLepusModuleFuncWrongArgNum = 2003;
// Lepus module function called with wrong argument type.
NSInteger const LynxErrorCodeLepusModuleFuncWrongArgType = 2004;
// Lepus module function executed with exception.
NSInteger const LynxErrorCodeLepusModuleFuncCallException = 2005;
// Lepus Module bussiness error reported by module function implementation.
NSInteger const LynxErrorCodeLepusModuleBussinessError = 2006;
// Lepus Module argument error.
NSInteger const LynxErrorCodeLepusModuleArgusError = 2007;

#pragma mark - Section: ImageResource
// Error for image resources.

// Error for unexpected big image.
NSInteger const LynxErrorCodeBigImage = 2100;
// Error for image resource provider.
NSInteger const LynxErrorCodePicSource = 2101;
// Error for FE design or user settings.
NSInteger const LynxErrorCodeFromUserOrDesign = 2102;
// Error for net error or others.
NSInteger const LynxErrorCodeFromTTNetOrOthers = 2199;

#pragma mark - Section: HMR
// Error for HMR.

// Error for HMR Lepus update.
NSInteger const LynxErrorCodeHmrLepusUpdate = 3000;

#pragma mark - Section: Binary
// Error for encode template binary.

// Error for encode template binary.
NSInteger const LynxErrorCodeBinary = 9901;

#pragma mark - Section: SSR
// Error for rendering page whose dom is constructed on server side.

// Fail SSR data to decode ssr data. Data is likely corrupted.
NSInteger const LynxErrorCodeSsrDecode = 10001;
// Error occurred when loadSSRData.
NSInteger const LynxErrorCodeLoadSsrData = 10002;
// Load SSR data with a higher API version than the version the sdk is supported.
NSInteger const LynxErrorCodeApiVersionNotSupported = 10003;
// The dom structure after hydration deviates from the SSR result, may caused by the difference of injected global data or template used for SSR and hydrate.
NSInteger const LynxErrorCodeHydrateResultDeviateFromSsrResult = 10004;

#pragma mark - Section: LynxResourceModule
// Error for prefetching resource from JS.

// Parameter error.
NSInteger const LynxErrorCodeResModuleParamsError = 11001;
// Imager prefetch helper not exist.
NSInteger const LynxErrorCodeResModuleImgPrefetchHelperNotExist = 11002;
// Resource service not exist.
NSInteger const LynxErrorCodeResModuleResourceServiceNotExist = 11003;


//!!!!! DO NOT MODIFY
//!!!!! See `tools/error_code/README.md`
// clang-format on
