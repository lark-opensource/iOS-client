//
//  IESGurdLRUCacheLinkedList.h
//  Pods
//
//  Created by 陈煜钏 on 2019/8/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdLRUCacheLinkedList : NSObject

@property (nonatomic, assign) NSInteger capacity;

- (NSArray<NSString *> *)allChannels;

- (void)appendLinkedNodeForChannel:(NSString *)channel;

- (void)bringLinkedNodeToHeadForChannel:(NSString *)channel;

- (NSArray<NSString *> *)channelsToBeDelete;

- (void)deleteLinkedNodeForChannel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
