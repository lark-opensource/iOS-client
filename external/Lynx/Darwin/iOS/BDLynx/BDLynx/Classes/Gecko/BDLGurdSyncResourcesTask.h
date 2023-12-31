//
//  BDLGurdSyncResourcesTask.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BDLGurdSyncResourcesOptions) {
  BDLGurdSyncResourcesOptionsNone = 0,
  BDLGurdSyncResourcesOptionsForceRequest = 1 << 0,  // 强制请求，即使gecko开关关闭
  BDLGurdSyncResourcesOptionsUrgent = 1 << 1,  // 满足gecko请求条件后，尽可能快地请求
  BDLGurdSyncResourcesOptionsDisableThrottle =
      1 << 2,  // 满足gecko请求条件后，每次都请求；默认一段时间内只请求一次
  BDLGurdSyncResourcesOptionsHighPriority = 1 << 3,  // 满足gecko请求条件后，高优请求
};

typedef void (^BDLGurdSyncResourcesTaskCompletion)(BOOL succeed,
                                                   NSDictionary<NSString *, NSNumber *> *info);

@interface BDLGurdSyncResourcesTask : NSObject

@property(nonatomic, readonly, copy) NSString *identifier;  // 根据channels生成特定identifier

@property(nullable, nonatomic, readonly, copy) NSString *accessKey;

@property(nonatomic, readonly, copy) NSArray<NSString *> *channelsArray;

@property(nullable, nonatomic, readonly, copy) NSString *businessDomain;

@property(nullable, nonatomic, readonly, copy) BDLGurdSyncResourcesTaskCompletion completion;

@property(nullable, nonatomic, copy) NSString *resourceVersion;

@property(nonatomic, assign) BDLGurdSyncResourcesOptions options;

@property(nonatomic, readonly, assign, getter=isExecuting) BOOL executing;

+ (instancetype)taskWithAccessKey:(NSString *_Nullable)accessKey
                         channels:(NSArray<NSString *> *)channels
                   businessDomain:(NSString *_Nullable)businessDomain
                       completion:(BDLGurdSyncResourcesTaskCompletion _Nullable)completion;

+ (instancetype)taskWithChannels:(NSArray<NSString *> *)channels
                  businessDomain:(NSString *_Nullable)businessDomain
                      completion:(BDLGurdSyncResourcesTaskCompletion _Nullable)completion;

- (BOOL)forceRequest;

@end

NS_ASSUME_NONNULL_END
