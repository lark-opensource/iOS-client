#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "IESFallbackSchemaResolver.h"
#import "IESPrefetch.h"
#import "IESPrefetchAPIConfigResolver.h"
#import "IESPrefetchAPIModel.h"
#import "IESPrefetchAPITemplate.h"
#import "IESPrefetchCacheModel+RequestModel.h"
#import "IESPrefetchCacheModel.h"
#import "IESPrefetchCacheProvider.h"
#import "IESPrefetchCacheStorageProtocol.h"
#import "IESPrefetchConfigResolver.h"
#import "IESPrefetchConfigTemplate.h"
#import "IESPrefetchDebugBizViewController.h"
#import "IESPrefetchDebugTemplateViewController.h"
#import "IESPrefetchDebugTool.h"
#import "IESPrefetchDebugViewController.h"
#import "IESPrefetchDefaultCacheStorage.h"
#import "IESPrefetchDefines.h"
#import "IESPrefetchFlatSchema+Private.h"
#import "IESPrefetchFlatSchema.h"
#import "IESPrefetchJSNetworkRequestModel.h"
#import "IESPrefetchLoader.h"
#import "IESPrefetchLoaderEvent.h"
#import "IESPrefetchLoaderPrivateProtocol.h"
#import "IESPrefetchLoaderProtocol.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchManager.h"
#import "IESPrefetchMonitorService.h"
#import "IESPrefetchOccasionConfigResolver.h"
#import "IESPrefetchOccasionTemplate.h"
#import "IESPrefetchParamModel.h"
#import "IESPrefetchProjectConfigResolver.h"
#import "IESPrefetchProjectTemplate.h"
#import "IESPrefetchRequestModel.h"
#import "IESPrefetchRuleConfigResolver.h"
#import "IESPrefetchRuleTemplate.h"
#import "IESPrefetchSchemaResolver.h"
#import "IESPrefetchTemplateOutput.h"
#import "IESPrefetchThreadSafeArray.h"
#import "IESPrefetchThreadSafeDictionary.h"
#import "IESSimpleSchemaResolver.h"
#import "IESWebViewSchemaResolver.h"

FOUNDATION_EXPORT double IESPrefetchVersionNumber;
FOUNDATION_EXPORT const unsigned char IESPrefetchVersionString[];
