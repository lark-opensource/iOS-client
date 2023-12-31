// Copyright © 2021 Bytedance. All rights reserved.

#ifndef BDXContextKeyDefines_h
#define BDXContextKeyDefines_h

/**
 * @brief BDXContext Keys
 * @see https://bytedance.feishu.cn/docs/doccnZbWV7UOeUk0iWmayFTz9fc#YOjgjr
 */

FOUNDATION_EXPORT NSString* const kBDXContextKeyGlobalProps;
FOUNDATION_EXPORT NSString* const kBDXContextKeyWidthMode;
FOUNDATION_EXPORT NSString* const kBDXContextKeyHeightMode;
FOUNDATION_EXPORT NSString* const kBDXContextKeyAccessKey;
FOUNDATION_EXPORT NSString* const kBDXContextKeyAid;
FOUNDATION_EXPORT NSString* const kBDXContextKeyBid;
FOUNDATION_EXPORT NSString* const kBDXContextKeyPrefetchBusiness;
FOUNDATION_EXPORT NSString* const kBDXContextKeyPrefetchInitData;

FOUNDATION_EXPORT NSString* const kBDXContextKeyContainerLifecycleDelegate;

FOUNDATION_EXPORT NSString* const kBDXContextKeyTemplateData;
FOUNDATION_EXPORT NSString* const kBDXContextKeySchemaParams;
FOUNDATION_EXPORT NSString* const kBDXContextKeyInitialData;
FOUNDATION_EXPORT NSString* const kBDXContextKeyInitialDataMarkState;

// Custom bridge class which inherits from IESJSBridge
FOUNDATION_EXPORT NSString* const kBDXContextKeyBridgeClass;

// Class conform to protocol BDXBridgeProvider
FOUNDATION_EXPORT NSString* const kBDXContextKeyBridgeProviderClasses;

FOUNDATION_EXPORT NSString* const kBDXContextKeyXBridgeMethods;
FOUNDATION_EXPORT NSString* const kBDXContextKeyMonitorSettingModel;

FOUNDATION_EXPORT NSString* const kBDXContextKeyCustomUIElements;
FOUNDATION_EXPORT NSString* const kBDXContextKeyProcessorConfig;
FOUNDATION_EXPORT NSString* const kBDXContextKeyWebViewConfig;
FOUNDATION_EXPORT NSString* const kBDXContextKeySecureLinkConfig;

FOUNDATION_EXPORT NSString* const kBDXContextKeyLoadingView;
FOUNDATION_EXPORT NSString* const kBDXContextKeyLoadFailedView;
FOUNDATION_EXPORT NSString* const kBDXContextKeyNavBar;
FOUNDATION_EXPORT NSString* const kBDXContextKeyNavBarReportHandle;
FOUNDATION_EXPORT NSString* const kBDXContextKeyNavBarShareHandle;
FOUNDATION_EXPORT NSString* const kBDXContextKeyContainerBackgroundColor;

#endif /* BDXContextKeyDefines_h */
