//
//  BDXResourceLoaderCDNProcessor.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "BDXRLCDNProcessor.h"

#import "BDXResourceLoader.h"
#import "BDXResourceProvider.h"
#import "NSData+BDXSource.h"
#import "NSError+BDXRL.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <TTNetworkDownloader/TTDownloadApi.h>
#import <TTNetworkManager/TTHttpResponse.h>
#import <mach/mach_time.h>

typedef void (^BDXResourceLoaderTTDownloadCompletion)(NSURL *_Nullable pathURL, StatusCode code, BOOL canRetry, NSError *_Nullable error);

@interface BDXRLCDNProcessor ()

/// Download params
@property(atomic, strong) DownloadGlobalParameters *downloadParameters;
/// 不需要重试的错误码
@property(nonatomic, strong) NSArray *endRetryCodes;
/// 为了解决完成下载后TTDownloadApi不释放resultBlock导致内部持有的变量也不会被释放的问题，将downloadCompletion作为self的成员，跟随self一同释放
@property(nonatomic, copy) BDXResourceLoaderTTDownloadCompletion downloadCompletion;

@end

@implementation BDXRLCDNProcessor

- (NSString *)resourceLoaderName
{
    return @"XDefaultCDNLoader";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[TTDownloadApi shareInstance] setDownlodingTaskCountMax:20];
        self.endRetryCodes = @[@(ERROR_FREE_SPACE_NOT_ENOUGH), @(ERROR_WRITE_DISK_FAILED), @(ERROR_DOWNLOAD_TASK_COUNT_OVERFLOW), @(ERROR_FREE_SPACE_NOT_ENOUGH_WHILE_MERGE), @(ERROR_CANCEL_SUCCESS)];
        [self configDownloadParams];
    }
    return self;
}

- (void)configDownloadParams
{
    DownloadGlobalParameters *params = [[DownloadGlobalParameters alloc] init];
    // 下载资源如果较大可以开启，较小效果不佳
    //        downloadParameters.isBackgroundDownloadEnable = YES;
    params.isCheckCacheValid = YES;
    params.retryTimeoutInterval = 3;
    params.sliceMaxRetryTimes = 3;
    params.contentLengthWaitMaxInterval = 1;
    params.isHttps2HttpFallback = YES;
    // High priority
    params.queuePriority = QUEUE_PRIORITY_HIGH;
    params.insertType = QUEUE_HEAD;
    params.isSkipGetContentLength = YES;
    self.downloadParameters = params;
}

- (void)downloadWithIdentity:(NSString *)identity URLString:(NSString *)URLString
{
    @weakify(self);
    TTDownloadProgressBlock progressBlock = ^(DownloadProgressInfo *progress) {

    };
    TTDownloadResultBlock resultBlock = ^(DownloadResultNotification *resultNotification) {
        @strongify(self);
        // 如果有地址，则成功返回
        StatusCode code = resultNotification.code;
        [BDXResourceLoader reportLog:[NSString stringWithFormat:@"BDXResourceLoader -- cdn download code %ld --", (long)code]];
        if (resultNotification.downloadedFilePath) {
            [BDXResourceLoader reportLog:[NSString stringWithFormat:@"Download successfully : id: %@ , url: %@", identity, URLString]];
            NSURL *pathURL = [NSURL fileURLWithPath:resultNotification.downloadedFilePath];
            !self.downloadCompletion ?: self.downloadCompletion(pathURL, code, NO, nil);
            return;
        }
        // 否则，处理失败逻辑
        NSString *errorMessage = resultNotification.downloaderLog ?: [NSString stringWithFormat:@"cdn error code %ld", resultNotification.code];
        BOOL canRetry = ![self.endRetryCodes containsObject:@(code)];
        [BDXResourceLoader reportLog:[NSString stringWithFormat:@"Download failed : %@; Code : "
                                                                @"%zd; Reason : %@; %@ retry",
                                                                identity, code, errorMessage, canRetry ? @"Can" : @"Can't"]];

        NSArray *responses = resultNotification.httpResponseArray;
        NSInteger httpCode = 0;
        if (responses && responses.count > 0) {
            id response = resultNotification.httpResponseArray[0];
            if (response && [response isKindOfClass:TTHttpResponse.class]) {
                httpCode = ((TTHttpResponse *)response).statusCode;
            }
        }
        NSDictionary *details = @{
            NSLocalizedDescriptionKey: errorMessage,
            @"httpCode": @(httpCode),
        };

        NSError *error = [[NSError alloc] initWithDomain:kBDXRLDomain code:code userInfo:details];
        !self.downloadCompletion ?: self.downloadCompletion(nil, code, canRetry, error);
    };
    // 注意：这里TTDownloadApi不会释放progress 与status Block，为了防止downloadCompletion不被释放，将其作为self的成员
    [[TTDownloadApi shareInstance] startDownloadWithKey:identity fileName:identity md5Value:nil urlLists:@[URLString] progress:progressBlock status:resultBlock userParameters:self.downloadParameters];
}

- (void)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler
{
    NSString *sourceURL = url;
    if (!BTD_isEmptyString([self.paramConfig sourceURL])) {
        // self.paramConfig中的sourceURL
        // 来自于对传入URL中参数的解析。如果不为空则优先使用
        sourceURL = [self.paramConfig sourceURL];
    }

    // 如果用户手动传入了cdn地址，则优先使用此地址
    if ([self.paramConfig cdnURL]) {
        sourceURL = [self.paramConfig cdnURL];
    }

    if (taskConfig.loadRetryTimes != 0) {
        self.downloadParameters.urlRetryTimes = taskConfig.loadRetryTimes;
    }

    BDXResourceProvider *resourceProvider = [BDXResourceProvider new];
    resourceProvider.res_originSourceURL = url;
    resourceProvider.res_sourceURL = sourceURL;
    resourceProvider.res_accessKey = [self.paramConfig accessKey];
    resourceProvider.res_bundleName = [self.paramConfig bundleName];
    resourceProvider.res_channelName = [self.paramConfig channelName];
    resourceProvider.res_cdnUrl = sourceURL;

    if ([sourceURL hasPrefix:@"http://"] || [sourceURL hasPrefix:@"https://"]) {
        NSString *urlString = sourceURL;
        NSString *identity = @"";
        if ([self.paramConfig addTimeStampInTTIdentity]) {
            identity = [NSString stringWithFormat:@"%@%llu", [BDXRLCDNProcessor identityWithUrl:sourceURL], mach_absolute_time()];
        } else {
            identity = [BDXRLCDNProcessor identityWithUrl:sourceURL];
        }
        @weakify(self);
        /// 每次下载都是一个新的CDNProcessor示例，不必担心block与URL不对应
        self.downloadCompletion = ^(NSURL *pathURL, StatusCode code, BOOL canRetry, NSError *_Nullable error) {
            @strongify(self);
            if (pathURL) {
                NSData *data = [NSData dataWithContentsOfURL:pathURL];
                if (data) {
                    if (code == ERROR_FILE_DOWNLOADED) { // File Had Downloaded. 6
                        data.bdx_SourceFrom = BDXResourceStatusCdnCache;
                    } else {
                        data.bdx_SourceFrom = BDXResourceStatusCdn;
                    }
                    resourceProvider.res_Data = data;
                    resourceProvider.res_sourceFrom = data.bdx_SourceFrom;
                }
                resourceProvider.res_localPath = pathURL.path;
                if (resolveHandler && !self.isCanceled) {
                    resolveHandler(resourceProvider, [self resourceLoaderName]);
                }
            } else {
                if (rejectHandler && !self.isCanceled) {
                    rejectHandler(error ?: [NSError new]);
                }
            }
        };
        [self downloadWithIdentity:identity URLString:urlString];
    } else {
        if (rejectHandler && !self.isCanceled) {
            rejectHandler([NSError errorWithCode:BDXRLErrorCodeURLInvalid message:@"Invalid URL"]);
        }
    }
}

- (void)cancelLoad
{
    self.isCanceled = YES;
}

- (void)dealloc
{
    // do nothing
}

+ (NSString *)identityWithUrl:(NSString *)urlString
{
    return [NSString stringWithFormat:@"BDX_resource_%@", [urlString btd_md5String]];
}

+ (void)deleteCDNCacheForResource:(id<BDXResourceProtocol>)resource
{
    NSString *sourceURL = [resource originSourceURL];
    if (!BTD_isEmptyString([resource sourceUrl])) {
        sourceURL = [resource sourceUrl];
    }
    if ([resource cdnUrl]) {
        sourceURL = [resource cdnUrl];
    }
    if (BTD_isEmptyString(sourceURL)) {
        return;
    }
    NSString *identity = [BDXRLCDNProcessor identityWithUrl:sourceURL];
    [[TTDownloadApi shareInstance] deleteDownloadWithURL:identity resultBlock:^(DownloadResultNotification *resultNotification) {
        NSString *state = @"failed";
        if (resultNotification.code == ERROR_DELETE_SUCCESS) {
            state = @"succeed";
        }
        NSDictionary *category = @{@"type": @"cdn", @"delete_state": state, @"code": @(resultNotification.code)};
        [[BDXResourceLoader monitor] reportWithEventName:@"bd_monitor_lynxLoadFailDeleteResource" bizTag:nil commonParams:@{@"url": sourceURL ?: @""} metric:nil category:category extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:NO];
        [BDXResourceLoader reportLog:[NSString stringWithFormat:@"CDNLoadFailDeleteResource : %@", sourceURL]];
    }];
}

@end
