//
//  IESAdLandingChannelInterceptor.m
//  IESWebKit
//
//  Created by li keliang on 2019/6/12.
//

#import "IESAdLandingChannelInterceptor.h"
#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
#import <IESGeckoKit/IESGeckoKit.h>
#endif

#import "NSString+IESFalconConvenience.h"

@interface IESAdLandingChannelFalconMetaData : NSObject<IESFalconMetaData>
@end

@implementation IESAdLandingChannelFalconMetaData
@synthesize falconData = _falconData;
@synthesize statModel = _statModel;
@end

@interface IESAdLandingChannelInterceptor ()

@property (nonatomic, copy) NSString *gurdAccessKey;

@end

@implementation IESAdLandingChannelInterceptor

- (instancetype)init
{
    return [self initWithGurdAccessKey:@""];
}

- (instancetype)initWithGurdAccessKey:(NSString *)gurdAccessKey
{
    NSCParameterAssert(gurdAccessKey.length != 0);
    self = [super init];
    if (self) {
        _gurdAccessKey = gurdAccessKey;
        _enable = YES;
        _channelQueryKey = @"ad_landing_channel";
    }
    return self;
}

#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request;
{
#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
    if (!self.enable || self.channelQueryKey.length == 0) {
        return nil;
    }
    
    NSString *adLandingChannel = [self adLandingChannelForURLRequest:request];
    if (adLandingChannel.length == 0) {
        return nil;
    }
    
    NSString *filePath = request.URL.path;
    NSData *falconData = [IESGurdKit dataForPath:filePath
                                       accessKey:self.gurdAccessKey
                                         channel:adLandingChannel];

    IESAdLandingChannelFalconMetaData *metaData = [[IESAdLandingChannelFalconMetaData alloc] init];
    metaData.falconData = falconData;
    
    IESFalconStatModel *statModel = [[IESFalconStatModel alloc] init];
    statModel.offlineStatus = (falconData.length > 0) ? 1 : 0;
    statModel.accessKey = self.gurdAccessKey;
    statModel.channel = adLandingChannel;
    statModel.mimeType = filePath.pathExtension ? : @"unknown";
    if (falconData.length == 0) {
        statModel.errorCode = 100;
    }
    statModel.falconDataLength = falconData.length;
    metaData.statModel = statModel;
    
    return metaData;
#else
    return nil;
#endif
}

#pragma mark - Private

- (NSString * _Nullable)adLandingChannelForURLRequest:(NSURLRequest *)request
{
    if (request.URL.absoluteString.length == 0) {
        // fix +[NSURLComponents initWithURL:resolvingAgainstBaseURL:]: nil URLString parameter crash
        return nil;
    }
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
    
    __block NSString *adLandingChannel = nil;
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:self.channelQueryKey]) {
            adLandingChannel = obj.value;
            *stop = YES;
        }
    }];
    
    return adLandingChannel;
}

@end

