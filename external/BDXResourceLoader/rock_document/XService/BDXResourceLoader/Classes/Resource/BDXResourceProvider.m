//
//  BDXResourceProvider.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import "BDXResourceProvider.h"

@implementation BDXResourceProvider

+ (instancetype)resourceWithURL:(NSURL *)url
{
    BDXResourceProvider *resourceProvider = [BDXResourceProvider new];
    resourceProvider.res_originSourceURL = url.absoluteString;
    return resourceProvider;
}

+ (void)trackLoadEventWithProvider:(BDXResourceProvider *)provider container:(UIView *_Nullable)container
{
    // for hook
}

+ (void)doTrackLoadEventWithProvider:(BDXResourceProvider *)provider container:(UIView *_Nullable)container
{
    // for hook
}

#pragma mark - BDXResourceProtocol

- (NSData *)resourceData
{
    return self.res_Data;
}

- (NSString *)channel
{
    return self.res_channelName;
}

- (NSString *)accessKey
{
    return self.res_accessKey;
}

- (uint64_t)version
{
    return self.res_version;
}

- (NSString *)bundle
{
    return self.res_bundleName;
}

- (nullable NSString *)cdnUrl
{
    return self.res_cdnUrl;
}

- (nullable NSString *)sourceUrl
{
    return self.res_sourceURL;
}

- (nullable NSString *)absolutePath
{
    return self.res_localPath;
}

- (BDXResourceStatus)resourceType
{
    return self.res_sourceFrom;
}

- (nullable NSString *)originSourceURL
{
    return self.res_originSourceURL;
}

@end
