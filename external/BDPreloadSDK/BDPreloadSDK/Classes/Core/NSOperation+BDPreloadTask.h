//
//  NSOperation+BDPreloadTask.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/14.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BDPreloadType) {
    BDPreloadTypeNormal,
    BDPreloadTypeHard,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSOperation (BDPreloadTask)

@property (nonatomic, strong) NSString *bdp_preloadKey;

@property (nonatomic, strong) NSString *bdp_scene;

@property (nonatomic, copy) dispatch_block_t bdp_timeoutBlock;

@property (nonatomic, assign) NSTimeInterval bdp_initTime;

@property (nonatomic, assign) NSTimeInterval bdp_startTime;

@property (nonatomic, assign) NSTimeInterval bdp_finishTime;

@property (nonatomic, assign, readonly) NSTimeInterval bdp_waitTime;

@property (nonatomic, assign) BOOL bdp_onlyWifi;

@property (nonatomic, assign) BDPreloadType bdp_preloadType;

@end

NS_ASSUME_NONNULL_END
