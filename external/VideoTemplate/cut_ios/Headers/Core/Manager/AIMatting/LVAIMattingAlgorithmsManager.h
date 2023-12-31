//
//  LVAIMattingAlgorithmsManager.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LVAIMattingAlgorithmsManager;
@protocol LVAIMattingAlgorithmsManagerDelegate <NSObject>
@optional
- (void)aiMattingAlgorithmsManagerDidDownloadAlgorithms:(LVAIMattingAlgorithmsManager *)manager;
@end

typedef void(^LVAIMattingCheckAlgorithmsReadyCompletion)(BOOL isAlgorithmsReady);
/// 智能抠图算法管理
@interface LVAIMattingAlgorithmsManager : NSObject
@property (nonatomic, assign, readonly) BOOL isAlgorithmsReady;
@property (nonatomic, copy, readonly, nullable) NSString *algorithmsMD5;
@property (nonatomic, weak) id<LVAIMattingAlgorithmsManagerDelegate> delegate;

- (BOOL)checkAlgorithmsReadySync;
- (void)checkAlgorithmsReadyAsync:(LVAIMattingCheckAlgorithmsReadyCompletion)completion;
+ (NSDictionary<NSString *, NSArray<NSString *> *> *)algorithmModelNames;
+ (void)downloadAIMattingAlgorithms;
- (void)downloadAIMattingAlgorithmsInBackgroundQueue;
- (void)downloadAIMattingAlgorithmsInBackgroundQueueWithCompletion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
