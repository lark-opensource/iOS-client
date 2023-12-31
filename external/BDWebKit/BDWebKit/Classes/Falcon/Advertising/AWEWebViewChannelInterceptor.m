//
//  AWEWebViewChannelInterceptor.m
//  AWEWebView
//
//  自定义拦截器
//  Created by 01 on 2020/3/22.
//


#import "AWEWebViewChannelInterceptor.h"
#import "BDWebKitUtil.h"
#import <BDWebKit/NSData+ETag.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDWebKit/NSString+IESFalconConvenience.h>

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdDelegateDispatcher.h>
#import <objc/runtime.h>

static dispatch_queue_t AWEFalconWebViewInterceptionDelegateDispatcherQueue(void);
#endif


@interface AWEWebViewFalconManifestItem : NSObject

@property (nonatomic) NSString *fileName;
@property (nonatomic) NSDictionary<NSString *, NSString *> *responseHeaders;

@end

@implementation AWEWebViewFalconManifestItem

@end

@interface AWEWebViewChannelFalconMetaData : NSObject<IESFalconMetaData>

@property (nonatomic) NSData * _Nullable falconData;

@property (nonatomic) IESFalconStatModel *statModel;

@property (nonatomic) NSDictionary *allHeaderFields;

@end

@implementation AWEWebViewChannelFalconMetaData

@end

@interface AWEWebViewChannelInterceptor ()

@property (nonatomic) NSDictionary *manifest;

@property (nonatomic, copy) NSString *channel; // 指定channel名
@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) AWEFalconWebViewGetChannelBlock channelBlock;
@property (nonatomic, copy) AWEFalconWebViewGetAccessKeyBlock accessKeyBlock;

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
@property (nonatomic, strong) IESGurdDelegateDispatcher<IESFalconGurdInterceptionDelegate> *delegateDispatcher;
#endif

@end

@implementation AWEWebViewChannelInterceptor

- (instancetype)initWithAccessKey:(NSString *)accessKey
                     channelBlock:(nonnull AWEFalconWebViewGetChannelBlock)channelBlock
{
    NSCParameterAssert(!BDWK_isEmptyString(accessKey) && !!channelBlock);
    self = [super init];
    if (self) {
        _enable = YES;
        _accessKey = accessKey;
        _channelBlock = channelBlock;
    }
    return self;
}

- (instancetype)initWithAccessKeyBlock:(AWEFalconWebViewGetAccessKeyBlock)accessKeyBlock
                          channelBlock:(AWEFalconWebViewGetChannelBlock)channelBlock
{
    NSCParameterAssert(!!accessKeyBlock && !!channelBlock);
    self = [super init];
    if (self) {
        _enable = YES;
        _channelBlock = channelBlock;
        _accessKeyBlock = accessKeyBlock;
    }
    return self;
}

- (void)readManifestJsonWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSString *cacheFlag = [NSString stringWithFormat:@"%@_%@", accessKey, channel];
    if ([objc_getAssociatedObject(self, _cmd) isKindOfClass:NSString.class] && [objc_getAssociatedObject(self, _cmd) isEqualToString:cacheFlag]) {
        return;
    }
    
    NSData *manifestData = [IESGurdKit dataForPath:@"manifest.json" accessKey:accessKey channel:channel];
    NSDictionary *manifest = [manifestData btd_jsonDictionary];

    if (![manifest isKindOfClass:NSDictionary.class]) {
        self.manifest = nil;
        return;
    }
    
    objc_setAssociatedObject(self, _cmd, cacheFlag, OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.manifest = manifest;
}

#pragma mark - Public

- (void)registerInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate
{
#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
    if (!self.enable) {
        return;
    }
    dispatch_async(AWEFalconWebViewInterceptionDelegateDispatcherQueue(), ^{
        if (!self.delegateDispatcher) {
            self.delegateDispatcher = (IESGurdDelegateDispatcher<IESFalconGurdInterceptionDelegate> *)
            [IESGurdDelegateDispatcher dispatcherWithProtocol:@protocol(IESFalconGurdInterceptionDelegate)];
        }
        [self.delegateDispatcher registerDelegate:gurdInterceptionDelegate];
    });
#endif
}

- (void)unregisterInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate
{
#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
    if (!self.enable) {
        return;
    }
    dispatch_async(AWEFalconWebViewInterceptionDelegateDispatcherQueue(), ^{
        [self.delegateDispatcher unregisterDelegate:gurdInterceptionDelegate];
    });
#endif
}

#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request
{
#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
    
    if (!self.enable) {
        return nil;
    }
   
    NSString *accessKey = self.accessKey;
    if (self.accessKeyBlock) {
        accessKey = self.accessKeyBlock(request.URL);
    }
    
    if (BDWK_isEmptyString(accessKey)) {
        return nil;
    }
    
    NSString *channel = self.channel;
    // block优先
    if (self.channelBlock) {
        channel = self.channelBlock(request.URL);
    }
    
    if (BDWK_isEmptyString(channel)) {
        return nil;
    }
    
    [self readManifestJsonWithAccessKey:accessKey channel:channel];
    
    NSString *URLStringWithoutQuery = request.URL.absoluteString;
    NSString *URLMd5 = [[URLStringWithoutQuery btd_md5String] lowercaseString];
    
    AWEWebViewChannelFalconMetaData *metaData = [self falconMetaDataWithURLMd5:URLMd5 accessKey:accessKey channel:channel];
    if (metaData.falconData.length == 0) {
        URLStringWithoutQuery = [request.URL.absoluteString ies_stringByTrimmingQueryString];
        URLMd5 = [[URLStringWithoutQuery btd_md5String] lowercaseString];
        metaData = [self falconMetaDataWithURLMd5:URLMd5 accessKey:accessKey channel:channel];
    }
    
    dispatch_async(AWEFalconWebViewInterceptionDelegateDispatcherQueue(), ^{
        [self.delegateDispatcher falconInterceptedRequest:request
                                        willLoadFromCache:(metaData.falconData.length > 0)
                                                statModel:metaData.statModel];
    });
    
    return metaData;
#else
    return nil;
#endif
}

- (AWEWebViewChannelFalconMetaData * _Nullable)falconMetaDataWithURLMd5:(NSString *)URLMd5 accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    AWEWebViewFalconManifestItem *manifestItem = [AWEWebViewFalconManifestItem new];
    if ([self.manifest[URLMd5] isKindOfClass:NSDictionary.class]) {
        manifestItem.fileName = self.manifest[URLMd5][@"fileName"];
        manifestItem.responseHeaders = [self.manifest[URLMd5][@"respHeader"] isKindOfClass:NSDictionary.class] ? self.manifest[URLMd5][@"respHeader"] : nil;
    }
    
    AWEWebViewChannelFalconMetaData *metaData = [[AWEWebViewChannelFalconMetaData alloc] init];
    
    if ([manifestItem isKindOfClass:AWEWebViewFalconManifestItem.class]) {
        metaData.falconData = [IESGurdKit dataForPath:manifestItem.fileName accessKey:accessKey channel:channel];
        metaData.allHeaderFields = manifestItem.responseHeaders;
    }
    
    metaData.statModel = (IESFalconStatModel *)({
        IESFalconStatModel *statModel = [[IESFalconStatModel alloc] init];
        statModel.offlineStatus = (metaData.falconData.length > 0) ? 1 : 0;
        statModel.accessKey = accessKey;
        statModel.channel = channel;
        if (metaData.falconData.length == 0) {
            statModel.errorCode = 100;
        }
        statModel.falconDataLength = metaData.falconData.length;
        statModel;
    });
    return metaData;
}

@end

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
dispatch_queue_t AWEFalconWebViewInterceptionDelegateDispatcherQueue(void)
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        queue = dispatch_queue_create("com.AWEFalcon.WebViewInterceptionDelegateDispatcherQueue", attr);
    });
    return queue;
}
#endif
