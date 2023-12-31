//
//  BDXResourceProvider.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <BDXServiceCenter/BDXResourceLoaderProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXResourceProvider : NSObject <BDXResourceProtocol>

@property(nonatomic, copy) NSString *res_accessKey;
@property(nonatomic, copy) NSString *res_channelName;
@property(nonatomic, copy) NSString *res_bundleName;
@property(nonatomic, assign) uint64_t res_version;

@property(nonatomic, strong) NSData *res_Data;
@property(nonatomic, assign) BDXResourceStatus res_sourceFrom;

@property(nonatomic, copy) NSString *res_originSourceURL;
@property(nonatomic, copy) NSString *res_sourceURL;
@property(nonatomic, copy) NSString *res_localPath;
@property(nonatomic, copy) NSString *res_cdnUrl;

@end

NS_ASSUME_NONNULL_END
