//
//  BDPAppPagePrefetcher.h
//  Timor
//
//  Created by 李靖宇 on 2019/11/25.
//

#import <Foundation/Foundation.h>
#import "BDPAppPagePrefetchDataModel.h"
@class BDPSchema;
@class BDPUniqueID;
@class OPPrefetchErrnoWrapper;

typedef NS_ENUM(NSInteger, BDPPrefetchDetail)
{
    BDPPrefetchDetailFetchNetError               = 22,            // 已发起预取，结果回来，预取结果失败(依赖网络库的结果)
    BDPPrefetchDetailFetchAndUseSuccess          = 100,           // 命中预取(发起预取时成功结果已在本地)
    BDPPrefetchDetailReuseRequestSuccess         = 101,           // 已发起预取，结果还没回来，复用结果(结果成功)
    BDPPrefetchDetailReuseRequestFail            = 102,           // 已发起预取，结果还没回来，复用结果(结果失败)
};

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppPagePrefetcher : NSObject

- (instancetype)initWithUniqueID:(BDPUniqueID*)uniqueID;

//TODO:与schema解耦
- (void)prefetchWithSchema:(BDPSchema*)schema prefetchDict:(NSDictionary *)prefetchDict prefetchRulesDict:(NSDictionary *)prefetchRulesDict backupPath:(nullable NSString *)backupPath isFromPlugin:(BOOL)isFromPlugin;

- (BOOL)shouldUsePrefetchCacheWithParam:(NSDictionary*)param uniqueID:(BDPUniqueID *)uniqueID requestCompletion:(PageRequestCompletionBlock)completion error:(OPPrefetchErrnoWrapper **)error;
@end

NS_ASSUME_NONNULL_END
