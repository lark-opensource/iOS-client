//
//  BDLynxProvider.m
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/2/21.
//

#import "BDXLynxResourceProvider.h"
#import <BDWebImage/BDImage.h>
#import <BDWebImage/BDImageCache.h>
#import <BDWebImage/BDWebImageManager.h>
#import <BDWebImage/UIImage+BDWebImage.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXMonitorProtocol.h>
#import <BDXServiceCenter/BDXResourceLoaderProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <mach/mach_time.h>
#import "BDXLynxKitUtils.h"

typedef void (^_Nonnull IMAGE_LOADER_CALLBACK)(UIImage *, NSError *, NSURL *);

static NSString *const kBDXLynxTempleteUrlDomain = @"kBDXLynxResourceUrlDomain";

static inline void bdx_lynxkit_dispatch_main_safe(dispatch_block_t block)
{
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface BDXLynxResource : NSObject <BDXResourceProtocol>
@property(nonatomic, copy) NSString *channelName;
@property(nonatomic, copy) NSString *bundleName;
@property(nonatomic, assign) uint64_t version;
@property(nonatomic, assign) BDXResourceStatus sourceFrom;
@property(nonatomic, copy) NSString *originSourceURL;
@property(nonatomic, copy) NSString *localPath;
@property(nonatomic, strong) NSData *resData;

+ (instancetype)resourceWithURL:(NSURL *)url;

@end

@implementation BDXLynxResource

+ (instancetype)resourceWithURL:(NSURL *)url
{
    BDXLynxResource *resource = [BDXLynxResource new];
    resource.originSourceURL = url.absoluteString;
    return resource;
}

- (nullable NSString *)absolutePath
{
    return self.localPath;
}

- (nullable NSString *)accessKey
{
    return nil;
}

- (nullable NSString *)bundle
{
    return self.bundleName;
}

- (nullable NSString *)cdnUrl
{
    return self.sourceUrl;
}

- (nullable NSString *)channel
{
    return self.channelName;
}

- (nullable NSData *)resourceData
{
    return self.resData;
}

- (BDXResourceStatus)resourceType
{
    return self.sourceFrom;
}

- (nullable NSString *)sourceUrl
{
    return self.originSourceURL;
}

@end

@interface BDXImageURLCacheKeyStorage ()

@property(nonatomic, strong) NSMutableArray *prefetchArray;

+ (instancetype)sharedInstance;
- (void)setPrefetchCacheKey:(NSString *)cacheKey;
- (BOOL)consumePrefetchedCacheKey:(NSString *)cacheKey;

@end

@implementation BDXImageURLCacheKeyStorage

static id _sharedInst = nil;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedInst) {
            _sharedInst = [[self alloc] init];
        }
    });
    return _sharedInst;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.prefetchArray = [[NSMutableArray alloc] init];
    }

    return self;
}

+ (void)setPrefetchCacheKey:(NSString *)cacheKey
{
    [[BDXImageURLCacheKeyStorage sharedInstance] setPrefetchCacheKey:cacheKey];;
}

- (void)setPrefetchCacheKey:(NSString *)cacheKey
{
    if (BTD_isEmptyString(cacheKey)) {
        return;
    }
    @synchronized(self) {
        if ( ! [_prefetchArray containsObject:cacheKey]) {
            [_prefetchArray addObject:cacheKey];
        }
    }
}

- (BOOL)consumePrefetchedCacheKey:(NSString *)cacheKey
{
    if (BTD_isEmptyString(cacheKey)) {
        return NO;
    }

    @synchronized(self) {
        BOOL isContain = [_prefetchArray containsObject:cacheKey];
        if (isContain) {
            /// 如果包含，则消费掉此次记录
            [_prefetchArray removeObject:cacheKey];
        }
        return isContain;
    }
}

@end

@implementation BDXLynxResourceProvider

- (NSURLSessionDataTask *)fallbackToLoadResourceWithUrl:(NSString *)url completionHandler:(void (^)(NSData *_Nullable data, NSError *_Nullable error))completionHandler
{
    BOOL hasParams = [url containsString:@"?"];
    NSString *seperator = hasParams ? @"&" : @"?";
    NSString *surl = [url stringByAppendingFormat:@"%@t=%llu", seperator, mach_absolute_time()];
    NSURL *nsUrl = [NSURL URLWithString:surl];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:nsUrl completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            completionHandler(nil, error);
            return;
        } else if (!data) {
            NSError *error = [NSError errorWithDomain:kBDXLynxTempleteUrlDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}];
            completionHandler(nil, error);
            return;
        } else if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode > 400) {
                NSError *error = [NSError errorWithDomain:kBDXLynxTempleteUrlDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Http Code is %ld", (long)httpResponse.statusCode]}];
                completionHandler(data, error);
                return;
            }
        }
        completionHandler(data, nil);
    }];

    [task resume];
    return task;
}

- (void)loadTemplateWithUrl:(NSString *)url onComplete:(LynxTemplateLoadBlock)callback
{
    /// Lynx is not support reset template provider.
    if (self.customTemplateProvider && [self.customTemplateProvider respondsToSelector:@selector(loadTemplateWithUrl:onComplete:)]) {
        [self.customTemplateProvider loadTemplateWithUrl:url onComplete:callback];
        return;
    }
    
    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    BDXResourceLoaderProcessorConfig *customProcessor = [self.context getObjForKey:kBDXContextKeyProcessorConfig];
    id<BDXResourceLoaderProtocol> resourceLoader = BDXSERVICE_WITH_DEFAULT(BDXResourceLoaderProtocol, bid);
    id<BDXMonitorProtocol> monitor = BDXSERVICE(BDXMonitorProtocol, nil);

    if (self.delegate) {
        [self.delegate resourceProviderDidStartLoadWithURL:url];
    }

    if (resourceLoader) {
        BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
        taskConfig.accessKey = self.accessKey;
        taskConfig.dynamic = self.dynamic;
        taskConfig.disableGurd = self.disableGurd;
        taskConfig.disableBuildin = self.disableBuildin;
        taskConfig.channelName = self.channel;
        taskConfig.bundleName = self.bundle;
        taskConfig.context = self.context;
        if (customProcessor) {
            taskConfig.processorConfig = customProcessor;
        }
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

        [resourceLoader fetchResourceWithURL:url container:(UIView *)self.lynxview taskConfig:taskConfig completion:^(id<BDXResourceProtocol> _Nullable resourceProvider, NSError *_Nullable error) {
            if (self.delegate) {
                [self.delegate resourceProviderDidFinsihLoadWithURL:url resource:resourceProvider error:error];
            }
            CFTimeInterval loadDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
            NSString *errorString = error.description ?: @"";
            if (resourceProvider.resourceData != nil) {
                callback(resourceProvider.resourceData, error);
                [monitor reportResourceStatus:(UIView *)self.lynxview resourceStatus:(BDXMonitorResourceStatus)resourceProvider.resourceType resourceType:BDXMonitorResourceTypeTemplate resourceURL:url resourceVersion:[NSString stringWithFormat:@"%llu", resourceProvider.version] extraInfo:@{@"error": errorString} extraMetrics:@{@"load_duration": @(loadDuration)}];
            } else {
                if (!error) {
                    error = [NSError errorWithDomain:kBDXLynxTempleteUrlDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}];
                }
                callback(nil, error);
                [monitor reportResourceStatus:(UIView *)self.lynxview resourceStatus:BDXMonitorResourceStatusFail resourceType:BDXMonitorResourceTypeTemplate resourceURL:url resourceVersion:[NSString stringWithFormat:@"0"] extraInfo:@{@"error": errorString} extraMetrics:@{@"load_duration": @(loadDuration)}];
            }
        }];
    } else {
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        [self fallbackToLoadResourceWithUrl:url completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate) {
                    BDXLynxResource *resource = [BDXLynxResource resourceWithURL:[NSURL URLWithString:url]];
                    resource.sourceFrom = BDXResourceStatusCdn;
                    [self.delegate resourceProviderDidFinsihLoadWithURL:url resource:resource error:error];
                }
                callback(data, error);
                CFTimeInterval loadDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                NSString *errorString = error.description ?: @"";
                if (error) {
                    [monitor reportResourceStatus:(UIView *)self.lynxview resourceStatus:BDXMonitorResourceStatusFail resourceType:BDXMonitorResourceTypeTemplate resourceURL:url resourceVersion:@"0" extraInfo:@{@"error": errorString} extraMetrics:@{@"load_duration": @(loadDuration)}];
                } else {
                    [monitor reportResourceStatus:(UIView *)self.lynxview resourceStatus:BDXMonitorResourceStatusCdn resourceType:BDXMonitorResourceTypeTemplate resourceURL:url resourceVersion:@"0" extraInfo:@{@"error": errorString} extraMetrics:@{@"load_duration": @(loadDuration)}];
                }
            });
        }];
    }
}

- (dispatch_block_t)loadImageWithURL:(NSURL *)url size:(CGSize)targetSize contextInfo:(nullable NSDictionary *)contextInfo completion:(LynxImageLoadCompletionBlock)completionBlock
{
    BOOL isRelativeURL = [BDXLynxKitUtils isRelativeURL:url];
    NSString *resultUrl = url.absoluteString;
    if (isRelativeURL) {
        NSString *sourceUrl = self.templateSourceURL;
        if ([url.absoluteString hasPrefix:@"./"]) {
            resultUrl = [NSString stringWithFormat:@"%@%@", [sourceUrl stringByReplacingOccurrencesOfString:[sourceUrl lastPathComponent] withString:@""], [url.absoluteString stringByReplacingOccurrencesOfString:@"./" withString:@"/"]];
        } else if ([url.absoluteString hasPrefix:@"../"]) {
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"../" options:NSRegularExpressionCaseInsensitive error:&error];
            NSUInteger numberOfPaths = [regex numberOfMatchesInString:url.absoluteString options:0 range:NSMakeRange(0, [url.absoluteString length])];
            NSString *pathUrlString = url.absoluteString;
            if (numberOfPaths > 0) {
                for (int i = 0; i < numberOfPaths; i++) {
                    pathUrlString = [pathUrlString stringByDeletingLastPathComponent];
                }
            }
            resultUrl = [NSString stringWithFormat:@"%@%@", [sourceUrl stringByDeletingLastPathComponent], pathUrlString];
        }
    }

    BDImageCacheType cacheType = BDImageCacheTypeMemory;

    // [url] -> [md5(local path)]
    NSString *cacheKey = [resultUrl btd_md5String];

    if ([contextInfo[LynxImageFetcherContextKeyDownsampling] boolValue]) {
        // can not use cache in this case
        [[BDWebImageManager sharedManager] requestImage:url options:BDImageRequestHighPriority | BDImageRequestContinueInBackground | BDImageRequestIgnoreQueue | BDImageRequestNeedCachePath | BDImageRequestPreloadAllFrames size:targetSize complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if (image) {
                [self handleImageCallback:cacheKey uiImage:image error:error callback:completionBlock url:url cacheType:cacheType];
            }
        }];
        return nil;
    }
    if ([[BDImageCache sharedImageCache] containsImageForKey:cacheKey type:cacheType]) {
        UIImage *cachedImage = [[BDImageCache sharedImageCache] imageForKey:cacheKey withType:&cacheType];
        if (cachedImage) {
            [self handleImageCallback:cacheKey uiImage:cachedImage error:nil callback:completionBlock url:url cacheType:cacheType];
            return nil;
        }
    }

    // Url that BDXResourceLoader cannot handle
    if ([BDXLynxKitUtils isResourceLoaderNotHandleURL:url]) {
        [[BDWebImageManager sharedManager] requestImage:url options:BDImageRequestDefaultPriority | BDImageRequestPreloadAllFrames complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if (request.finished && data) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    BDImage *cdnImage = [BDImage imageWithData:[data mutableCopy]];
                    [self cacheImage:cacheKey uiImage:cdnImage imageData:data cacheType:cacheType];
                    [self handleImageCallback:cacheKey uiImage:cdnImage error:error callback:completionBlock url:url cacheType:cacheType];

                    return;
                });
            } else if (image) {
                [self cacheImage:cacheKey uiImage:image imageData:nil cacheType:cacheType];
                [self handleImageCallback:cacheKey uiImage:image error:error callback:completionBlock url:url cacheType:cacheType];

                return;
            }
        }];
        return nil;
    }
    
    /// 此时，未命中缓存。如果当前cacheKey 是预取的图片，则上报miss埋点
    if ([[BDXImageURLCacheKeyStorage sharedInstance] consumePrefetchedCacheKey:cacheKey]) {
        id<BDXMonitorProtocol> monitor = BDXSERVICE(BDXMonitorProtocol, nil);
        BDXSchemaParam *standardParams = [self.context getObjForKey:kBDXContextKeySchemaParams];
        NSString *schemaUrl = @"";
        if ([standardParams.originURL isKindOfClass:NSURL.class]) {
            schemaUrl = standardParams.originURL.absoluteString;
        }
        [monitor reportWithEventName:@"bdx_monitor_preload_image_cache_miss" bizTag:nil commonParams:@{@"url": url.absoluteString ?: @""} metric:nil category:@{@"schema":schemaUrl ?: @""} extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:NO];
    }

    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    BDXResourceLoaderProcessorConfig *customProcessor = [self.context getObjForKey:kBDXContextKeyProcessorConfig];
    id<BDXResourceLoaderProtocol> resourceLoader = BDXSERVICE(BDXResourceLoaderProtocol, bid);
    if (resourceLoader) {
        BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
        taskConfig.accessKey = self.accessKey;
        taskConfig.disableGurd = self.disableGurd;
        taskConfig.disableBuildin = self.disableBuildin;
        taskConfig.context = self.context;
        if (customProcessor) {
            taskConfig.processorConfig = customProcessor;
        }
        id<BDXResourceLoaderTaskProtocol> task = [resourceLoader fetchResourceWithURL:resultUrl container:(UIView *)self.lynxview taskConfig:taskConfig completion:^(id<BDXResourceProtocol> _Nullable resourceProvider, NSError *_Nullable error) {
            if ([[BDImageCache sharedImageCache] containsImageForKey:cacheKey type:cacheType]) {
                BDImageCacheType tempCacheType = cacheType;
                UIImage *cachedImage = [[BDImageCache sharedImageCache] imageForKey:cacheKey withType:&tempCacheType];
                [self handleImageCallback:cacheKey uiImage:cachedImage error:nil callback:completionBlock url:url cacheType:tempCacheType];
                return;
            }

            NSData *imageData = resourceProvider.resourceData;
            if (imageData) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    BDImage *image = [BDImage imageWithData:imageData];
                    [self cacheImage:cacheKey uiImage:image imageData:imageData cacheType:cacheType];
                    [self handleImageCallback:cacheKey uiImage:image error:nil callback:completionBlock url:url cacheType:cacheType];

                    return;
                });
            } else {
                [[BDWebImageManager sharedManager] requestImage:url options:BDImageRequestHighPriority | BDImageRequestContinueInBackground | BDImageRequestIgnoreQueue | BDImageRequestNeedCachePath | BDImageRequestPreloadAllFrames complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                    if (request.finished && data) {
                        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                            BDImage *cdnImage = [BDImage imageWithData:[data mutableCopy]];
                            [self cacheImage:cacheKey uiImage:cdnImage imageData:data cacheType:cacheType];
                            [self handleImageCallback:cacheKey uiImage:cdnImage error:error callback:completionBlock url:url cacheType:cacheType];
                            return;
                        });
                    } else if (image) {
                        [self cacheImage:cacheKey uiImage:image imageData:nil cacheType:cacheType];
                        [self handleImageCallback:cacheKey uiImage:image error:error callback:completionBlock url:url cacheType:cacheType];
                        return;
                    }
                }];
            }
        }];
        return ^{
            [task cancelTask];
        };
    } else {
        NSURLSessionDataTask *task = [self fallbackToLoadResourceWithUrl:resultUrl completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = nil;
                if (data) {
                    image = [UIImage imageWithData:data];
                }
                completionBlock(image, error, url);
            });
        }];
        return ^{
            [task cancel];
        };
    }
}

- (dispatch_block_t)loadCanvasImageWithURL:(NSURL *)url contextInfo:(nullable NSDictionary *)contextInfo completion:(nonnull LynxCanvasImageLoadCompletionBlock)completionBlock
{
    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    BDXResourceLoaderProcessorConfig *customProcessor = [self.context getObjForKey:kBDXContextKeyProcessorConfig];
    id<BDXResourceLoaderProtocol> resourceLoader = BDXSERVICE_WITH_DEFAULT(BDXResourceLoaderProtocol, bid);
    if (resourceLoader) {
        BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
        taskConfig.accessKey = self.accessKey;
        taskConfig.context = self.context;
        if (customProcessor) {
            taskConfig.processorConfig = customProcessor;
        }
        id<BDXResourceLoaderTaskProtocol> task = [resourceLoader fetchResourceWithURL:url.absoluteString container:(UIView *)self.lynxview taskConfig:taskConfig completion:^(id<BDXResourceProtocol> _Nullable resourceProvider, NSError *_Nullable error) {
            if (resourceProvider.resourceData != nil) {
                completionBlock(resourceProvider.resourceData, error, url);
            } else {
                if (!error) {
                    error = [NSError errorWithDomain:kBDXLynxTempleteUrlDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}];
                }
                completionBlock(nil, error, url);
            }
        }];
        return ^{
            [task cancelTask];
        };
    } else {
        NSURLSessionDataTask *task = [self fallbackToLoadResourceWithUrl:url.absoluteString completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(data, error, url);
            });
        }];
        return ^{
            [task cancel];
        };
    }
}

- (dispatch_block_t)loadResourceWithURL:(NSURL *)url type:(LynxFetchResType)type completion:(LynxResourceLoadCompletionBlock)completionBlock
{
    BDXResourceLoaderProcessorConfig *customProcessor = [self.context getObjForKey:kBDXContextKeyProcessorConfig];
    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    id<BDXResourceLoaderProtocol> resourceLoader = BDXSERVICE_WITH_DEFAULT(BDXResourceLoaderProtocol, bid);
    if (resourceLoader) {
        BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
        taskConfig.accessKey = self.accessKey;
        taskConfig.disableGurd = self.disableGurd;
        taskConfig.disableBuildin = self.disableBuildin;
        taskConfig.context = self.context;
        if (customProcessor) {
            taskConfig.processorConfig = customProcessor;
        }
        id<BDXResourceLoaderTaskProtocol> task = [resourceLoader fetchResourceWithURL:url.absoluteString container:(UIView *)self.lynxview taskConfig:taskConfig completion:^(id<BDXResourceProtocol> _Nullable resourceProvider, NSError *_Nullable error) {
            if (resourceProvider.resourceData != nil) {
                completionBlock(NO, resourceProvider.resourceData, error, url);
            } else {
                if (!error) {
                    error = [NSError errorWithDomain:kBDXLynxTempleteUrlDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}];
                }
                completionBlock(NO, nil, error, url);
            }
        }];
        return ^{
            [task cancelTask];
        };
    } else {
        NSURLSessionDataTask *task = [self fallbackToLoadResourceWithUrl:url.absoluteString completionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(NO, data, error, url);
            });
        }];
        return ^{
            [task cancel];
        };
    }
}

- (NSString*)redirectURL:(NSString*)urlString
{
    NSString *bid = [self.context getObjForKey:kBDXContextKeyBid];
    id<BDXResourceLoaderProtocol> resourceLoader = BDXSERVICE_WITH_DEFAULT(BDXResourceLoaderProtocol, bid);
    if (resourceLoader) {
        BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
        taskConfig.accessKey = self.accessKey;
        taskConfig.disableGurd = self.disableGurd;
        taskConfig.disableBuildin = self.disableBuildin;
        taskConfig.context = self.context;
        taskConfig.dynamic = @(0);     // 此时强制设置0
        taskConfig.onlyLocal = @(YES); // 此时强制设置onlyLocal
        taskConfig.syncTask = @(YES);  // 设置同步返回
        taskConfig.onlyPath = @(YES);  // 不读取data，仅获得本地路径
        __block NSString *filePathUrlString = urlString;
        [resourceLoader fetchResourceWithURL:urlString container:(UIView *)self.lynxview taskConfig:taskConfig completion:^(id<BDXResourceProtocol> _Nullable resourceProvider, NSError *_Nullable error) {
            if ( ! BTD_isEmptyString(resourceProvider.absolutePath)) {
                NSURL *url = [[NSURL alloc] initFileURLWithPath:resourceProvider.absolutePath];
                filePathUrlString = url.absoluteString;
            }
        }];
        return filePathUrlString;
    } else {
        return urlString;
    }
}

- (void)cacheImage:(NSString *)cackeKey uiImage:(UIImage *)uiImage imageData:(nullable NSData *)imageData cacheType:(BDImageCacheType)cacheType
{
    if (![[BDImageCache sharedImageCache] containsImageForKey:cackeKey type:cacheType]) {
        [[BDImageCache sharedImageCache] setImage:uiImage imageData:imageData forKey:cackeKey withType:cacheType];
    }
}

- (void)handleImageCallback:(NSString *)cacheKey uiImage:(UIImage *)uiImage error:(nullable NSError *)error callback:(IMAGE_LOADER_CALLBACK)callback url:(NSURL *)url cacheType:(BDImageCacheType)cacheType
{
    if (!uiImage) {
        bdx_lynxkit_dispatch_main_safe(^{
            callback(uiImage, error, url);
        });
        return;
    }
    if ([uiImage isKindOfClass:[BDImage class]]) {
        BDImage *bdIamge = (BDImage *)uiImage;
        if (![[BDImageCache sharedImageCache] containsImageForKey:cacheKey type:cacheType]) {
            [[BDImageCache sharedImageCache] setImage:uiImage imageData:nil forKey:cacheKey withType:cacheType];
        }
        if (bdIamge.isAnimateImage) {
            if (bdIamge.codeType == BDImageCodeTypeWebP) {
                [bdIamge bd_awebpToGifDataWithCompletion:^(NSData *_Nullable gifData, NSError *_Nullable error) {
                    UIImage *aniImage = [UIImage bd_imageWithGifData:gifData];
                    bdx_lynxkit_dispatch_main_safe(^{
                        callback(aniImage, error, url);
                    });
                    return;
                }];
            } else {
                UIImage *aniImage = [UIImage bd_imageWithGifData:bdIamge.animatedImageData];
                bdx_lynxkit_dispatch_main_safe(^{
                    callback(aniImage, error, url);
                });
                return;
            }
        } else {
            bdx_lynxkit_dispatch_main_safe(^{
                callback(bdIamge, error, url);
            });
            return;
        }
    }
    bdx_lynxkit_dispatch_main_safe(^{
        callback(uiImage, error, url);
    });
    return;
}

@end
