// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXERRORCODE_H_
#define DARWIN_COMMON_LYNX_LYNXERRORCODE_H_

//!!!!! DO NOT MODIFY
//!!!!! See `tools/error_code/README.md`

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// clang-format off

#pragma mark - Section: Success
// Success section

// Error code for no error.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeSuccess;

#pragma mark - Section: Fatal Error
// Fatal Error section, one should fallback or retry when encounter this error section.

// Error occurred when loadTemplate, one should retry loadTemplate.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLoadTemplate;
// Error occurred when Layout, one should retry or fallback
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLayout;
// Error occurred when fetch template resource.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeTemplateProvider;
// Error occurred when find TemplateEntry. It indicates one use the Feature `Dynamic Components` but do not register specific components, See Error message for more infomation.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeRuntimeEntry;
// multi thread strategy can not support the List
FOUNDATION_EXPORT NSInteger const LynxErrorCodeMultiThreadNotSupportList;

#pragma mark - Section: JavaScript
// JavaScript related error.

// Error occurred when executing JavaScript code. Check JavaScript call stack in error message for more information.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeJavaScript;
// Warning occurred when executing JavaScript code. Check JavaScript call stack in error message for more information.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeJsWarning;

#pragma mark - Section: Resource
// Resource related error.

// Error occurred when fetch resource. Check error message for more information.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeForResourceError;
// Component name in the List Cell is not exist. You should check whether the name is wrong or the component is not registered.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeComponentNotExist;

#pragma mark - Section: Update
// Error in update data pipeline.

// Some unknown error in Update data pipeline. Check error message for more information.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeUpdate;
// Input Parameter of Lepus Render function is not valid.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeDataBinding;
// `element_` in `DynamicCSSStylesManager` is null.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeDom;
// The parameter in `TemplateData#fromString()` is not a valid JSON string.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeParseData;

#pragma mark - Section: Canvas
// Error in lynx Canvas.

// Error in Lynx Canvas.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeCanvas;

#pragma mark - Section: Exception
// Error in Java or Objc Logic.

// Error in Java or Objc Logic.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeException;

#pragma mark - Section: BaseLib
// Error in perf collector.

// Error in perf collector.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeBaseLib;

#pragma mark - Section: Jni
// Error in JNI call.

// error in JNI call. Check the Java stacktrace in error message.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeJni;

#pragma mark - Section: NativeModules
// Error in NativeModules call. See issue: #1510

// One called a module that do not be registered.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleNotExist;
// One called a module function that do not be registered.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleFuncNotExist;
// One called a module function with wrong arguments count.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleFunWrongArgNum;
// One called a module fuction with wrong argument type.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleFuncWrongArgType;
// The module function call encountered a exception. Check error message for exception stack trace.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleFuncCallException;
// Module business error reported by module function implementation.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleBusinessError;
// The promise module function parameter is not a function.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleFuncPromiseArgNotFunc;
// The promise module function parameter count is wrong.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeModuleFuncPromiseArgNumWrong;

#pragma mark - Section: Event
// Error in Lynx Event.

// Error in Lynx Event.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeEvent;

#pragma mark - Section: Lepus
// Error in Lepus.

// Error in Lepus.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepus;

#pragma mark - Section: MainFlow
// Error in render main flow.

// A place error code, which is not used.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeMainFlow;
// LynxView is not destroyed in UI thread.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLynxViewDestroyNotOnUi;
// SyncFlush in a non-ui thread.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeSyncFlushInNonUiThread;

#pragma mark - Section: Css
// Error in CSS module

// Error in CSS module.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeCSS;

#pragma mark - Section: Asset
// Error in CSS related logic.

// Error in CSS related logic.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeAsset;

#pragma mark - Section: Cli
// Error in CSS related logic.

// Error in CSS related logic.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeCli;

#pragma mark - Section: DynamicComponent
// Error in dynamic component related logic.

// failed when load a dynamic component. Check error message for component info.
FOUNDATION_EXPORT NSInteger const LynxErrorDynamicComponentLoadFail;
// Load an empty dynamic component template data.
FOUNDATION_EXPORT NSInteger const LynxErrorDynamicComponentFileEmpty;
// The dynamic component template data cannot be decoded.
FOUNDATION_EXPORT NSInteger const LynxErrorDynamicComponentDecodeFail;

#pragma mark - Section: ExternalSource
// Error in load external source.

// Error in load external source.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeExternalSource;

#pragma mark - Section: EventException
// Error for event.

// Error for event.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeEventException;

#pragma mark - Section: ElementWorklet
// Error for element worklet

// Error for lepus call exception.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusCallException;
// Error for raf call exception.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeRafCallException;
// Error for worklet module exception
FOUNDATION_EXPORT NSInteger const LynxErrorCodeWorkletModuleException;

#pragma mark - Section: LepusMethod
// Error for lepus methods

// Lepus method call success.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusSuccess;
// Lepus Module do not exist.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleNotExist;
// Lepus module function do not exist.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleFuncNotExist;
// Lepus module function called with wrong arguments number.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleFuncWrongArgNum;
// Lepus module function called with wrong argument type.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleFuncWrongArgType;
// Lepus module function executed with exception.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleFuncCallException;
// Lepus Module bussiness error reported by module function implementation.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleBussinessError;
// Lepus Module argument error.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLepusModuleArgusError;

#pragma mark - Section: ImageResource
// Error for image resources.

// Error for unexpected big image.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeBigImage;
// Error for image resource provider.
FOUNDATION_EXPORT NSInteger const LynxErrorCodePicSource;
// Error for FE design or user settings.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeFromUserOrDesign;
// Error for net error or others.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeFromTTNetOrOthers;

#pragma mark - Section: HMR
// Error for HMR.

// Error for HMR Lepus update.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeHmrLepusUpdate;

#pragma mark - Section: Binary
// Error for encode template binary.

// Error for encode template binary.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeBinary;

#pragma mark - Section: SSR
// Error for rendering page whose dom is constructed on server side.

// Fail SSR data to decode ssr data. Data is likely corrupted.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeSsrDecode;
// Error occurred when loadSSRData.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeLoadSsrData;
// Load SSR data with a higher API version than the version the sdk is supported.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeApiVersionNotSupported;
// The dom structure after hydration deviates from the SSR result, may caused by the difference of injected global data or template used for SSR and hydrate.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeHydrateResultDeviateFromSsrResult;

#pragma mark - Section: LynxResourceModule
// Error for prefetching resource from JS.

// Parameter error.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeResModuleParamsError;
// Imager prefetch helper not exist.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeResModuleImgPrefetchHelperNotExist;
// Resource service not exist.
FOUNDATION_EXPORT NSInteger const LynxErrorCodeResModuleResourceServiceNotExist;

NS_ASSUME_NONNULL_END

//!!!!! DO NOT MODIFY
//!!!!! See `tools/error_code/README.md`
// clang-format on

#endif  // DARWIN_COMMON_LYNX_LYNXERRORCODE_H_
