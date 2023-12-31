//
//  IESAdSplashChannelInterceptor.m
//  Pods
//
//  Created by 陈煜钏 on 2019/12/2.
//

#import "IESAdSplashChannelInterceptor.h"

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdDelegateDispatcher.h>
#define IESFalconAdSplashInterceptorEnable  1
#endif

#import <BDWebKit/NSData+ETag.h>
#import <BDWebKit/NSString+IESFalconConvenience.h>

#if IESFalconAdSplashInterceptorEnable
static dispatch_queue_t IESFalconAdSplashInterceptionDelegateDispatcherQueue(void);
#endif

@interface IESAdSplashChannelFalconMetaData : NSObject<IESFalconMetaData>
@end

@implementation IESAdSplashChannelFalconMetaData
@synthesize falconData = _falconData;
@synthesize statModel = _statModel;
@end

@interface IESAdSplashChannelInterceptor ()

@property (nonatomic, copy) NSString *gurdAccessKey;

@property (nonatomic, copy) IESFalconAdSplashGetChannelBlock getChannelBlock;

#if IESFalconAdSplashInterceptorEnable
@property (nonatomic, strong) IESGurdDelegateDispatcher<IESFalconGurdInterceptionDelegate> *delegateDispatcher;
#endif

@end

@implementation IESAdSplashChannelInterceptor

- (instancetype)init
{
    return [self initWithGurdAccessKey:@"" getChannelBlock:^NSString * _Nonnull(NSURL * _Nonnull URL) {
        return nil;
    }];
}

- (instancetype)initWithGurdAccessKey:(NSString *)gurdAccessKey getChannelBlock:(nonnull IESFalconAdSplashGetChannelBlock)getChannelBlock
{
    NSCParameterAssert(gurdAccessKey.length != 0 && !!getChannelBlock);
    self = [super init];
    if (self) {
        _gurdAccessKey = gurdAccessKey;
        _getChannelBlock = getChannelBlock;
    }
    return self;
}

#pragma mark - Public

- (void)registerInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate
{
#if IESFalconAdSplashInterceptorEnable
    dispatch_async(IESFalconAdSplashInterceptionDelegateDispatcherQueue(), ^{
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
#if IESFalconAdSplashInterceptorEnable
    dispatch_async(IESFalconAdSplashInterceptionDelegateDispatcherQueue(), ^{
        [self.delegateDispatcher unregisterDelegate:gurdInterceptionDelegate];
    });
#endif
}

#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request;
{
#if IESFalconAdSplashInterceptorEnable
    if (!self.getChannelBlock) {
        return nil;
    }
    NSString *channel = self.getChannelBlock(request.URL);
    if (channel.length == 0) {
        return nil;
    }
    
    NSString *URLStringWithoutQuery = [request.URL.absoluteString ies_stringByTrimmingQueryString];
    NSData *URLData = [URLStringWithoutQuery dataUsingEncoding:NSUTF8StringEncoding];
    NSData *falconData = [IESGurdKit dataForPath:[[URLData ies_md5String] lowercaseString]
                                       accessKey:self.gurdAccessKey
                                         channel:channel];
    
    IESAdSplashChannelFalconMetaData *metaData = [[IESAdSplashChannelFalconMetaData alloc] init];
    metaData.falconData = falconData;
    
    IESFalconStatModel *statModel = [[IESFalconStatModel alloc] init];
    statModel.offlineStatus = (falconData.length > 0) ? 1 : 0;
    statModel.accessKey = self.gurdAccessKey;
    statModel.channel = channel;
    if (falconData.length == 0) {
        statModel.errorCode = 100;
    }
    statModel.falconDataLength = falconData.length;
    metaData.statModel = statModel;
    
    dispatch_async(IESFalconAdSplashInterceptionDelegateDispatcherQueue(), ^{
        [self.delegateDispatcher falconInterceptedRequest:request
                                        willLoadFromCache:(falconData.length > 0)
                                                statModel:statModel];
    });
    
    return metaData;
#else
    return nil;
#endif
}

@end

#if IESFalconAdSplashInterceptorEnable
dispatch_queue_t IESFalconAdSplashInterceptionDelegateDispatcherQueue(void)
{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        queue = dispatch_queue_create("com.IESFalcon.AdSplashInterceptionDelegateDispatcherQueue", attr);
    });
    return queue;
}
#endif
