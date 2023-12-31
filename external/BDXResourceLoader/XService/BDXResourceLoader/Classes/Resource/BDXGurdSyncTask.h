//
//  BDXGurdSyncTask.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#ifndef BDXGurdSyncTask_h
#define BDXGurdSyncTask_h

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BDXGurdSyncResourcesOptions) {
    BDXGurdSyncResourcesOptionsNone = 0,
    BDXGurdSyncResourcesOptionsForceRequest = 1 << 0,    //强制请求，即使gecko开关关闭
    BDXGurdSyncResourcesOptionsUrgent = 1 << 1,          //满足gecko请求条件后，尽可能快地请求
    BDXGurdSyncResourcesOptionsDisableThrottle = 1 << 2, //满足gecko请求条件后，每次都请求；默认一段时间内只请求一次
    BDXGurdSyncResourcesOptionsHighPriority = 1 << 3,    //满足gecko请求条件后，高优请求
};

typedef NS_ENUM(NSInteger, BDXGurdSyncTaskState) { BDXGurdSyncTaskStateWaiting, BDXGurdSyncTaskStateExecuting, BDXGurdSyncTaskStateFinished };

typedef NS_ENUM(NSInteger, BDXGurdSyncResourcesPollingPriority) {
    BDXGurdSyncResourcesPollingPriorityNone,
    // High priority
    BDXGurdSyncResourcesPollingPriorityLevel1,
    // Normal priority
    BDXGurdSyncResourcesPollingPriorityLevel2,
    // Low priority
    BDXGurdSyncResourcesPollingPriorityLevel3
};

typedef NS_ENUM(NSInteger, BDXGurdDownloadPriority) { BDXGurdDownloadPriorityLow, BDXGurdDownloadPriorityMedium, BDXGurdDownloadPriorityHigh, BDXGurdDownloadPriorityUserInteraction };

extern NSString *const kBDXGurdHighPriorityGroupName;
extern NSString *const kBDXGurdNormalGroupName;

@interface BDXGurdSyncResourcesResult : NSObject

@property(nonatomic, assign, getter=isSuccessfully) BOOL successfully;

@property(nonatomic, copy) NSDictionary<NSString *, NSNumber *> *info;

@property(nonatomic, assign, getter=isThrottled) BOOL throttled;

@end

typedef void (^BDXGurdSyncTaskCompletion)(BDXGurdSyncResourcesResult *result);

@interface BDXGurdSyncTask : NSObject

@property(nonatomic, readonly, copy) NSString *accessKey;

@property(nullable, nonatomic, readonly, copy) NSArray<NSString *> *channelsArray;

@property(nullable, nonatomic, readonly, copy) NSString *groupName; //默认是 default

@property(nullable, nonatomic, copy) NSString *businessDomain;

@property(nullable, nonatomic, copy) NSString *resourceVersion;

@property(nonatomic, assign) BDXGurdSyncResourcesOptions options;

@property(nonatomic, assign) BDXGurdSyncResourcesPollingPriority pollingPriority;

@property(nonatomic, assign) BDXGurdDownloadPriority downloadPriority;

@property(atomic, readonly, assign, getter=isExecuting) BOOL executing;

@property(atomic, readonly, assign) BDXGurdSyncTaskState state;

@property(nonatomic, assign) BOOL disableThrottle;

@property(nonatomic, readonly, assign) BOOL forceRequest;

+ (instancetype)taskWithAccessKey:(NSString *_Nonnull)accessKey groupName:(NSString *_Nullable)groupName channelsArray:(NSArray<NSString *> *_Nullable)channelsArray completion:(BDXGurdSyncTaskCompletion _Nullable)completion;

- (void)addCompletionOfTask:(BDXGurdSyncTask *)task;
- (void)callCompletionsWithResult:(BDXGurdSyncResourcesResult *)result;

@end

NS_ASSUME_NONNULL_END

#endif /* BDXGurdSyncTask_h */
