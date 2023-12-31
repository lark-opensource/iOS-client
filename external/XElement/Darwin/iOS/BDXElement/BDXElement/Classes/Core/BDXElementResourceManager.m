//
//  BDXElementResourceManager.m
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import "BDXElementResourceManager.h"
#import "BDXElementAdapter.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <Lynx/LynxView.h>
#import <SSZipArchive/SSZipArchive.h>
#import <Lynx/LynxEnv.h>
#import <Lynx/LynxDebugger.h>

@interface BDXElementResourceManager()

@property (nonatomic) NSMutableDictionary<NSString *, NSMutableArray *> *fetchingResourceCallbacks;

@end

static NSString * const lynxResourceDownloadPath = @"%@/Documents/%@-download";

@implementation BDXElementResourceManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BDXElementResourceManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
        instance.fetchingResourceCallbacks = [NSMutableDictionary new];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}


+ (NSString *)zipTempCachePathForURL:(NSURL *)URL
{
    NSString *cacheDirector = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.bytedance.x-element.temp"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirector]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirector withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [cacheDirector stringByAppendingPathComponent:URL.absoluteString.btd_md5String];
}

+ (NSString *)unzipCachePathForURL:(NSURL *)URL
{
    NSString *cacheDirector = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.bytedance.x-element.videocaches"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirector]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirector withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [cacheDirector stringByAppendingPathComponent:URL.absoluteString.btd_md5String];
}

+ (void)unzipFile:(NSURL *)location toPath:(NSString *)unzipPath completionHandler:(void (^)(NSURL *location, NSURL *unzipURL, NSError * _Nullable error))completionHandler
{
    if (!location.isFileURL) {
        !completionHandler ?: completionHandler(location, nil, [NSError errorWithDomain:@"com.bytedance.x-element" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"unzip url not file url"}]);
        return;
    }
    
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:location.path isDirectory:&isDirectory];
    
    if (!fileExists) {
        !completionHandler ?: completionHandler(location, nil, [NSError errorWithDomain:@"com.bytedance.x-element" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"not found file at path"}]);
        return;
    }
    if (isDirectory) {
        !completionHandler ?: completionHandler(location, location, nil);
        return;
    }
    
    NSError *error;
    NSString *tmpZipPath = [BDXElementResourceManager zipTempCachePathForURL:location];
    
    [[NSFileManager defaultManager] copyItemAtPath:location.path toPath:tmpZipPath error:&error];
    
    if (error) {
        !completionHandler ?: completionHandler(location, nil, error);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        [SSZipArchive unzipFileAtPath:tmpZipPath toDestination:unzipPath overwrite:YES password:nil error:&error];
        if (!error) {
            [[NSFileManager defaultManager] removeItemAtPath:tmpZipPath error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completionHandler ?: completionHandler(location, [NSURL fileURLWithPath:unzipPath], error);
        });
    });
}

+ (LynxView *)lynxViewFrom:(NSDictionary *)context {
  return context[BDXElementContextContainerKey];
}

+ (NSMutableDictionary *)pickOutLynxViewFrom:(NSDictionary *)context {
  NSMutableDictionary *mutableContext = [context mutableCopy];
  if (context[BDXElementContextContainerKey]) {
    [mutableContext removeObjectForKey:BDXElementContextContainerKey];
  }
  return mutableContext;
}


+ (NSDictionary *)genContext:(NSMutableDictionary *)mutableContext
                withLynxView:(LynxView *)lynxView {
  if (lynxView) {
    mutableContext[BDXElementContextContainerKey] = lynxView;
  }
  return mutableContext;
}



#pragma mark - Private Methods
- (NSString *)downloadDestinationPath {
    NSString *homeDirectory = NSHomeDirectory();
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *filePath = [NSString stringWithFormat:lynxResourceDownloadPath, homeDirectory, guid];
    return filePath;
}

#pragma mark - Public Methods

- (void)downloadZipFileWithURL:(NSURL *)URL completionHandler:(void (^)(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error))completionHandler
{
    NSString *unzipPath = [BDXElementResourceManager unzipCachePathForURL:URL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:unzipPath]) {
        // 如果有缓存直接返回
        !completionHandler ?: completionHandler(URL, [NSURL fileURLWithPath:unzipPath], nil);
        return;
    }
    
    if (URL.isFileURL) {
        [BDXElementResourceManager unzipFile:URL toPath:unzipPath completionHandler:^(NSURL *location, NSURL *unzipURL, NSError * _Nullable error) {
            !completionHandler ?: completionHandler(URL, unzipURL, error);
        }];
        return;
    }
    
    __weak id<BDXElementNetworkDelegate> delegate = BDXElementAdapter.sharedInstance.networkDelegate;
    LynxDownloadCompletionHandler downloadCompletionHandler = ^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            !completionHandler ?: completionHandler(URL, location, error);
            return;
        }
        
        [BDXElementResourceManager unzipFile:location toPath:unzipPath completionHandler:^(NSURL *location, NSURL *unzipURL, NSError * _Nullable error) {
            !completionHandler ?: completionHandler(URL, unzipURL, error);
        }];
    };
    if (delegate != nil && [delegate respondsToSelector:@selector(downloadTaskWithRequest:targetPath:completionHandler:)]) {
        [delegate downloadTaskWithRequest:[URL absoluteString]
                  targetPath:[self downloadDestinationPath]
                  completionHandler:downloadCompletionHandler];
    } else {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
        NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:downloadCompletionHandler];
        [downloadTask resume];
    }
}


- (void)resourceZipFileWithURL:(NSURL *)aURL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)strongContext completionHandler:(void (^)(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error))completionHandler
{
  
  __weak LynxView *weakLynxView = [BDXElementResourceManager lynxViewFrom:strongContext];
  NSMutableDictionary *contextInBlock = [BDXElementResourceManager pickOutLynxViewFrom:strongContext];
  
    NSURL *requestUrl = [self getRemoteURLWithRelativeURL:aURL baseURL:aBaseURL error:nil] ?: aURL;
    
    void(^fetchSuccessfulBlock)(NSURL * _Nullable url) = ^(NSURL * _Nullable url) {
        NSString *unzipPath = [BDXElementResourceManager unzipCachePathForURL:url];
        NSURL *unzipURL = [url copy];
        
        // if cache exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:unzipPath]) {
            !completionHandler ?: completionHandler(requestUrl, [NSURL fileURLWithPath:unzipPath], nil);
            return;
        }
        if ([unzipURL.pathExtension isEqualToString:@"zip"]){
            [BDXElementResourceManager unzipFile:unzipURL toPath:unzipPath completionHandler:^(NSURL *location, NSURL *unzipURL, NSError * _Nullable error) {
                if (error) {
                    // error, go default strategy
                    [self downloadZipFileWithURL:requestUrl completionHandler:completionHandler];
                } else {
                    !completionHandler ?: completionHandler(requestUrl, unzipURL, error);
                }
            }];
        } else {
            !completionHandler ?: completionHandler(requestUrl, unzipURL, nil);
        }
    };
    
    __weak __typeof(self)weakSelf = self;
    void(^fetchLocalFileDefaultBlock)(void) = ^(void) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.resourceDelegate respondsToSelector:@selector(fetchLocalFileWithURLString:context:completionHandler:)]) {
            NSString *urlString = [strongSelf urlStringWithURL:requestUrl];
            [strongSelf.resourceDelegate fetchLocalFileWithURLString:urlString context:[BDXElementResourceManager genContext:contextInBlock withLynxView:weakLynxView] completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
                if (error || !url) {
                    [strongSelf downloadZipFileWithURL:requestUrl completionHandler:completionHandler];
                } else {
                    fetchSuccessfulBlock(url);
                }
            }];
            return;
        } else {
            [strongSelf downloadZipFileWithURL:requestUrl completionHandler:completionHandler];
        }
    };
    
    LynxView* lynxView = [strongContext objectForKey: BDXElementContextContainerKey];
    if (lynxView.resourceFetcher && [lynxView.resourceFetcher respondsToSelector:@selector(fetchLocalFileWithURLString:context:completionHandler:)] ) {
        NSString *urlString = [self urlStringWithURL:requestUrl];
        [lynxView.resourceFetcher fetchLocalFileWithURLString:urlString context:strongContext completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            if (error || !url) {
              fetchLocalFileDefaultBlock();
            } else {
              fetchSuccessfulBlock(url);
            }
        }];
    } else {
        fetchLocalFileDefaultBlock();
    }
    
}

- (void)resourceDataWithURL:(NSURL *)aURL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)strongContext completionHandler:(void (^)(NSURL *url, NSData * _Nullable data, NSError * _Nullable error))completionHandler
{
  
  __weak LynxView *weakLynxView = [BDXElementResourceManager lynxViewFrom:strongContext];
  NSMutableDictionary *contextInBlock = [BDXElementResourceManager pickOutLynxViewFrom:strongContext];
  
    NSString *requestKey = [self getRemoteURLWithRelativeURL:aURL baseURL:aBaseURL error:nil].absoluteString ?: aURL.absoluteString;
    
    @synchronized (self) {
        if (!self.fetchingResourceCallbacks[requestKey] ) {
            self.fetchingResourceCallbacks[requestKey]  = [NSMutableArray new];
        }
        
        if (completionHandler) {
            NSMutableArray *waitingCallbacks = self.fetchingResourceCallbacks[requestKey];
            [waitingCallbacks addObject:completionHandler];
        }
        
        if ([self.fetchingResourceCallbacks[requestKey] count] > 1) {
            return;
        }
    }
    
    __weak __typeof(self)weakSelf = self;
    void (^wrappedCompletionHandler)(NSURL *, NSData * _Nullable, NSError * _Nullable) = ^(NSURL *url, NSData * _Nullable data, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        @synchronized (strongSelf) {
            NSMutableArray *waitingCallbacks = strongSelf.fetchingResourceCallbacks[requestKey];
            [waitingCallbacks enumerateObjectsUsingBlock:^(void (^handler)(NSURL *, NSData * _Nullable, NSError * _Nullable), NSUInteger idx, BOOL * _Nonnull stop) {
                handler(url, data, error);
            }];
            if(error == nil && data != nil && [[LynxEnv sharedInstance] recordEnable]){
                [LynxDebugger recordResource:data withKey:url.absoluteString];
            }
            strongSelf.fetchingResourceCallbacks[requestKey] = nil;
        }
    };
    
    void (^block)(void) = ^() {
        NSError *error;
        NSURL *URL = [self getRemoteURLWithRelativeURL:aURL baseURL:aBaseURL error:&error];
        if (error) {
            !wrappedCompletionHandler ?: wrappedCompletionHandler(aURL, nil, error);
            return;
        }
        if (!URL) {
            URL = aURL;
        }
        
        __weak id<BDXElementNetworkDelegate> delegate = BDXElementAdapter.sharedInstance.networkDelegate;
        LynxRequestCompletionHandler completionHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse isKindOfClass:NSHTTPURLResponse.class] && httpResponse.statusCode >= 400 && !error) {
                error = [NSError errorWithDomain:@"BDXElementErrorDomain" code:httpResponse.statusCode userInfo:@{
                    NSLocalizedDescriptionKey: @"Failed to fetch resource."
                }];
            }
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                !wrappedCompletionHandler ?: wrappedCompletionHandler(URL, data, error);
            });
        };
        if (delegate != nil && [delegate respondsToSelector:@selector(requestForBinaryWithResponse:completionHandler:)]) {
            [delegate requestForBinaryWithResponse:[URL absoluteString] completionHandler:completionHandler];
        } else {
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:URL] completionHandler:completionHandler];
            [task resume];
        }
    };
    
    
    void (^fetchResourceDataCompletionBlock)(NSData * _Nullable data, NSError * _Nullable error) = ^(NSData * _Nullable data, NSError * _Nullable error) {
        BOOL shouldFallback = YES;
        BDXElementShouldFallbackBlock shouldFallbackBlock = contextInBlock[BDXElementContextShouldFallbackBlockKey];
        if (shouldFallbackBlock) {
            shouldFallback = shouldFallbackBlock(error);
        }
        if (data || !shouldFallback) {
            !wrappedCompletionHandler ?: wrappedCompletionHandler(aURL, data, error);
        } else {
            block();
        }
    };
    
    NSString *urlString = [self urlStringWithURL:aURL];
    
    void(^defaultFetchResourceBlock)(void) = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.resourceDelegate respondsToSelector:@selector(fetchResourceDataWithURLString:context:completionHandler:)]) {
            [strongSelf.resourceDelegate fetchResourceDataWithURLString:urlString context:[BDXElementResourceManager genContext:contextInBlock withLynxView:weakLynxView] completionHandler:fetchResourceDataCompletionBlock];
            return;
        } else {
            block();
        }
    };
    
    
    LynxView* lynxView = [strongContext objectForKey: BDXElementContextContainerKey];
    if (lynxView.resourceFetcher && [lynxView.resourceFetcher respondsToSelector:@selector(fetchResourceDataWithURLString:context:completionHandler:)] ) {
        [lynxView.resourceFetcher fetchResourceDataWithURLString:urlString context:strongContext completionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (error) {
                defaultFetchResourceBlock();
            } else {
                fetchResourceDataCompletionBlock(data, error);
            }
        }];
    } else {
        defaultFetchResourceBlock();
    }
}

- (void)fetchLocalFileWithURL:(NSURL *)aURL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)strongContext completionHandler:(void (^)(NSURL *localUrl, NSURL *remoteUrl, NSError * _Nullable error))completionHandler
{
  
  __weak LynxView *weakLynxView = [BDXElementResourceManager lynxViewFrom:strongContext];
  NSMutableDictionary *contextInBlock = [BDXElementResourceManager pickOutLynxViewFrom:strongContext];
  
    __weak __typeof(self)weakSelf = self;
    
    void (^block)(void) = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSError *error;
        NSURL *URL = [strongSelf getRemoteURLWithRelativeURL:aURL baseURL:aBaseURL error:&error];
        !completionHandler ?: completionHandler(nil, URL ?: aURL, error);
    };
    
    void(^defaultFetchBlock)(void) = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.resourceDelegate respondsToSelector:@selector(fetchLocalFileWithURLString:context:completionHandler:)]) {
            NSString *urlString = [strongSelf urlStringWithURL:aURL];
            [strongSelf.resourceDelegate fetchLocalFileWithURLString:urlString context:[BDXElementResourceManager genContext:contextInBlock withLynxView:weakLynxView] completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
                if (url) {
                    !completionHandler ?: completionHandler(url, nil, nil);
                } else {
                    block();
                }
            }];
        } else {
            block();
        }
    };
    
    LynxView* lynxView = [strongContext objectForKey: BDXElementContextContainerKey];
    if (lynxView.resourceFetcher && [lynxView.resourceFetcher respondsToSelector:@selector(fetchLocalFileWithURLString:context:completionHandler:)] ) {
        NSString *urlString = [self urlStringWithURL:aURL];
        [lynxView.resourceFetcher fetchLocalFileWithURLString:urlString context:strongContext completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            if (url) {
                !completionHandler ?: completionHandler(url, nil, nil);
            } else {
                defaultFetchBlock();
            }
        }];
    } else {
        defaultFetchBlock();
    }
}


- (void)fetchFileWithURL:(NSURL *)URL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)strongContext completionHandler:(void (^)(NSURL *localUrl, NSURL *remoteUrl, NSError * _Nullable error))completionHandler {
  
  __weak LynxView *weakLynxView = [BDXElementResourceManager lynxViewFrom:strongContext];
  NSMutableDictionary *contextInBlock = [BDXElementResourceManager pickOutLynxViewFrom:strongContext];
  
  __weak __typeof(self)weakSelf = self;

  
  [self fetchLocalFileWithURL:URL baseURL:aBaseURL context:strongContext completionHandler:^(NSURL * _Nonnull localUrl, NSURL * _Nonnull remoteUrl, NSError * _Nullable error) {
    
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    
    if (!error && localUrl) {
      !completionHandler ? : completionHandler(localUrl, remoteUrl, error);
    } else {
      
      NSString *localPath = [BDXElementResourceManager unzipCachePathForURL:URL];
      if ([URL pathExtension]) {
        localPath = [NSString stringWithFormat:@"%@.%@", localPath, [URL pathExtension]];
      }
      
      if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
          // 如果有缓存直接返回
          !completionHandler ?: completionHandler([NSURL fileURLWithPath:localPath], URL, nil);
      } else {
        // try download data
        [strongSelf resourceDataWithURL:URL baseURL:aBaseURL context:[BDXElementResourceManager genContext:contextInBlock withLynxView:weakLynxView] completionHandler:^(NSURL * _Nonnull url, NSData * _Nullable data, NSError * _Nullable error) {
          if (!error && data) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              BOOL succ = [data writeToFile:localPath atomically:YES];
              dispatch_async(dispatch_get_main_queue(), ^{
                if (succ) {
                  !completionHandler ? : completionHandler([NSURL fileURLWithPath:localPath], url, nil);
                } else {
                  !completionHandler ? : completionHandler(nil, url, [NSError errorWithDomain:@"save audio file failed" code:-1 userInfo:nil]);
                }
              });
            });
          } else {
            !completionHandler ? : completionHandler(nil, url, error);
          }
          
        }];
      }
    }
  }];
  
}

#pragma mark - Private

- (NSString *)urlStringWithURL:(NSURL *)url
{
    NSString *urlString = url.absoluteString;
    if (urlString.length > 0 && url.baseURL.query.length > 0) {
        urlString = [NSString stringWithFormat:@"%@?%@", urlString, url.baseURL.query];
    }
    return urlString;
}

- (NSURL *)getRemoteURLWithRelativeURL:(NSURL *)aURL baseURL:(nullable NSURL *)aBaseURL error:(NSError **)error {
    NSURL *URL = aURL;
    NSURL *baseURL = aBaseURL;
    NSString *schema = URL.scheme ?: @"relative";
    
    if (!URL) {
        if (error) {
            *error = [NSError errorWithDomain:@"url parameters error" code:-1 userInfo:nil];
        }
        return nil;
    }
    
    if ([schema isEqualToString:@"bundle"]) {
        NSMutableArray<NSString *> *components = [[URL.path componentsSeparatedByString:@"/"] mutableCopy];
        if ([components firstObject].length == 0) {
            [components removeObjectAtIndex:0];
        }
        
        NSBundle *bundle = nil;
        if (components.count <= 1) {
            bundle = [NSBundle mainBundle];
        } else {
            NSString *path = [[NSBundle mainBundle] pathForResource:components.firstObject ofType:@"bundle"];
            bundle = [NSBundle bundleWithPath:path];
            [components removeObjectAtIndex:0];
        }
        return [bundle URLForResource:[components componentsJoinedByString:@"/"] withExtension:nil];
    }
    else if ([schema isEqualToString:@"relative"]) {
        baseURL = baseURL ? [baseURL URLByDeletingLastPathComponent] : [[NSBundle mainBundle] bundleURL];
        if (!URL.path) {
            if (error) {
                *error = [NSError errorWithDomain:@"URL.path parameters error" code:-1 userInfo:nil];
            }
            return nil;
        }
        return [baseURL URLByAppendingPathComponent:URL.path];
    }
    return aURL;
}

@end
