//
//  BDDYCSessionChallenge.h
//  BDDynamically
//
//  Created by zuopengliu on 7/6/2018.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

#if BDAweme
__attribute__((objc_runtime_name("AWECFJeopardizeHarm")))
#elif BDNews
__attribute__((objc_runtime_name("TTDShrubZone")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDAntelope")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDBroccoli")))
#endif
@interface BDDYCSessionDelegate : NSObject
<
NSURLSessionDelegate
>

+ (instancetype)shared;

@end


@interface NSURLSession (BDDYCSession)

+ (NSURLSessionDataTask *)bddyc_dataTaskWithRequest:(NSURLRequest *)request
                                  completionHandler:(void (^)(NSData * _Nullable data,
                                                              NSURLResponse * _Nullable response,
                                                              NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
