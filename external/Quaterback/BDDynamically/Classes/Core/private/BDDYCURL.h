//
//  BDDYCURL.h
//  BDDynamically
//
//  Created by zuopengliu on 22/6/2018.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN


/**
 Reference:
 https://tools.ietf.org/html/rfc1808
 URI 格式：
 scheme:[//authority]path[?query][#fragment]
 
 BDDynamically 协议格式：
 scheme://product/[business/]action?query_params
 
 path = business + action
 
 */

#if BDAweme
__attribute__((objc_runtime_name("AWECFGallant")))
#elif BDNews
__attribute__((objc_runtime_name("TTDPermeate")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDSanction")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDDisproof")))
#endif
@interface BDDYCURL : NSObject
/**
 BDDynamically 协议 scheme
 */
+ (NSString *)scheme;

@property (nullable, readonly, copy) NSString *scheme;
@property (nullable, readonly, copy) NSString *product;
@property (nullable, readonly, copy) NSString *business;
@property (nullable, readonly, copy) NSString *action;
@property (nullable, readonly, copy) NSString *parameters;

#pragma mark - Creation

+ (instancetype)DYCURLWithNSURL:(NSURL *)url;
+ (instancetype)DYCURLWithProduct:(NSString *)product
                         business:(NSString *)business
                           action:(NSString *)action
                       parameters:(NSDictionary *)params;
- (instancetype)initWithProduct:(NSString *)product
                       business:(NSString *)business
                         action:(NSString *)action
                     parameters:(NSDictionary *)params;

- (NSURL *)toNSURL;

#pragma mark - check

- (BOOL)canHandle;
+ (BOOL)canHandleURL:(NSURL *)url;

@end

@interface BDDYCURL (StakeSchemes)
+ (instancetype)startDYCURL;
+ (instancetype)closeDYCURL;
+ (instancetype)fetchDYCURL;

- (BOOL)isStartScheme;
- (BOOL)isCloseScheme;
- (BOOL)isFetchScheme;
@end


NS_ASSUME_NONNULL_END
