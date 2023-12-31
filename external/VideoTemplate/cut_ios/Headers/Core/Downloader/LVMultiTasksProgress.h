//
//  LVMultiTasksProgress.h
//  LVTemplate
//
//  Created by haoxian on 2019/11/15.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface LVMultiTasksProgress: NSObject

typedef void(^LVProgressCallback)(CGFloat progress);

@property (nonatomic, assign, readonly) CGFloat progress;

@property (nonatomic, copy, nullable) LVProgressCallback progressHandler;


+ (instancetype)taskIDs:(NSArray<NSString *> *)taskIDs;

- (instancetype)initWithTaskIDs:(NSArray<NSString *> *)taskIDs;

- (instancetype)init;

- (void)setProportion:(CGFloat)proportion forTaskID:(NSString *)taskID;

- (void)addTaskID:(NSString *)taskID;

- (void)removeTaskID:(NSString *)taskID;

- (void)updateProgress:(CGFloat)progress forTaskID:(NSString *)taskID;

- (void)completeForTaskID:(NSString *)taskID;

- (void)complete;

@end

NS_ASSUME_NONNULL_END
