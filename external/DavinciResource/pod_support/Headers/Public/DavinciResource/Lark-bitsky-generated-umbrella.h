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

#import "AlgorithmResourceConfig.h"
#import "AlgorithmResourceGlobalSettings.h"
#import "AlgorithmResourceHandler.h"
#import "AlgorithmResourceProtocol.h"
#import "DAVCreator.h"
#import "DAVExecutorExport.h"
#import "DAVFile.h"
#import "DAVFileExport.h"
#import "DAVHTTPClientDelegate.h"
#import "DAVHttpClient.h"
#import "DAVHttpClientCallback.h"
#import "DAVHttpClientDefine.h"
#import "DAVNetworkCreator.h"
#import "DAVPubDefine.h"
#import "DAVPublicUtil.h"
#import "DAVResource.h"
#import "DAVResourceFetchCallback.h"
#import "DAVResourceHandler.h"
#import "DAVResourceIdParser.h"
#import "DAVResourceManager.h"
#import "DAVResourceProtocol.h"
#import "DAVResourceTask.h"
#import "DAVTaskQueue.h"
#import "DAVThread.h"
#import "DAVThreadPool.h"
#import "DefaultExecutor.h"
#import "Executor.h"
#import "ExecutorCreator.h"
#import "IBuildInModelFinder.h"
#import "IRequirementsPeeker.h"
#import "IdGenerator.h"
#import "LokiResource.h"
#import "LokiResourceConfig.h"
#import "LokiResourceHandler.h"
#import "UrlResourceHandler.h"
#import "UrlResourceProtocol.h"
#import "file_platform.h"
#import "json_forward.hpp"
#import "miniz.h"
#import "zip.h"

FOUNDATION_EXPORT double DavinciResourceVersionNumber;
FOUNDATION_EXPORT const unsigned char DavinciResourceVersionString[];
