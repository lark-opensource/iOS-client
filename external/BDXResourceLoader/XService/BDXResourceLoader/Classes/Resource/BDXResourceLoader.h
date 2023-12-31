//
//  BDXResourceLoader.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#import <BDXServiceCenter/BDXResourceLoaderProtocol.h>
#import <BDXServiceCenter/BDXService.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBDXRLDomain;

@interface BDXResourceLoader : NSObject <BDXResourceLoaderProtocol>

@property(nonatomic, strong) BDXResourceLoaderConfig *loaderConfig;
@property(nonatomic, weak) BDXContext *context;

+ (void)reportLog:(NSString *)message;
+ (void)reportError:(NSString *)message;
+ (id<BDXMonitorProtocol>)monitor;

+ (NSString *)appid;

@end

@interface BDXRLTask : NSObject <BDXResourceLoaderTaskProtocol>

@property(nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END
