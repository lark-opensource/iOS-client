//
//  BDXLynxResourceProvider.h
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/2/21.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxImageFetcher.h>
#import <Lynx/LynxResourceFetcher.h>
#import <Lynx/LynxTemplateProvider.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXLynxView;
@class BDXContext;
@protocol BDXResourceProtocol;

@protocol BDXLynxResourceProviderDelegate <NSObject>

- (void)resourceProviderDidStartLoadWithURL:(NSString *)url;

- (void)resourceProviderDidFinsihLoadWithURL:(NSString *)url resource:(nullable id<BDXResourceProtocol>)resource error:(nullable NSError *)error;

@end

@interface BDXLynxResourceProvider : NSObject <LynxTemplateProvider, LynxImageFetcher, LynxResourceFetcher>

@property(nonatomic, weak) id<BDXLynxResourceProviderDelegate> delegate;

@property(nonatomic, copy) NSString *templateSourceURL;
@property(nonatomic, copy) NSString *accessKey;
@property(nonatomic, copy) NSString *channel;
@property(nonatomic, copy) NSString *bundle;
@property(nonatomic, copy) NSNumber *dynamic;
@property(nonatomic, copy) NSNumber *disableGurd;    /// 不读取Gecko下载数据
@property(nonatomic, copy) NSNumber *disableBuildin; /// 不读取内置数据

@property(nonatomic, weak) LynxView *lynxview;
@property(nonatomic, weak) BDXContext *context;

@property (nonatomic, weak, nullable) id <LynxTemplateProvider> customTemplateProvider;

@end

@interface BDXImageURLCacheKeyStorage : NSObject

+ (void)setPrefetchCacheKey:(NSString *)cacheKey;

@end

NS_ASSUME_NONNULL_END
