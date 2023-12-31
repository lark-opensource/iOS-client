//
// Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import <Foundation/Foundation.h>
#import "BDCTAPIService.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTNetworkManager : NSObject

+ (void)requestForResponseWithUrl:(NSString *)url method:(NSString *)method params:(NSDictionary *_Nullable)params binaryNames:(NSArray *_Nullable)binaryNames binaryDatas:(NSArray *_Nullable)binaryDatas completion:(BytedCertHttpResponseCompletion)completion;
+ (void)requestForResponseWithUrl:(NSString *)url method:(NSString *)method params:(NSDictionary *_Nullable)params binaryNames:(NSArray *_Nullable)binaryNames binaryDatas:(NSArray *_Nullable)binaryDatas headerField:(NSDictionary *_Nullable)headerField completion:(BytedCertHttpResponseCompletion)completion;

@end

NS_ASSUME_NONNULL_END
