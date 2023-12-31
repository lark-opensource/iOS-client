//
//  IESGurdSyncResourcesGroup.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/12/20.
//

#import "IESGurdSyncResourcesGroup.h"

@interface IESGurdSyncResourcesGroup ()

@property (nonatomic, copy) IESGurdSyncStatusDictionaryBlock completion;

@property (nonatomic, strong) dispatch_group_t group;

@property (nonatomic, strong) NSMutableDictionary *statusDictionary;

@property (nonatomic, assign, getter=isSuccessful) BOOL successful;

@end

@implementation IESGurdSyncResourcesGroup

+ (instancetype)groupWithCompletion:(IESGurdSyncStatusDictionaryBlock)completion;
{
    IESGurdSyncResourcesGroup *group = [[self alloc] init];
    group.completion = completion;
    group.group = dispatch_group_create();
    group.statusDictionary = [NSMutableDictionary dictionary];
    group.successful = YES;
    return group;
}

- (void)enter
{
    dispatch_group_enter(self.group);
}

- (void)leaveWithChannel:(NSString *)channel
            isSuccessful:(BOOL)isSuccessful
                  status:(IESGurdSyncStatus)status
{
    if (!isSuccessful) {
        self.successful = NO;
    }
    @synchronized (self.statusDictionary) {
        [self.statusDictionary setObject:@(status) forKey:channel];
    }
    dispatch_group_leave(self.group);
}

- (void)notifyWithBlock:(dispatch_block_t _Nullable)block
{
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        @synchronized(self.statusDictionary) {
            if (self.isSuccessful) {
                [self.statusDictionary setObject:@(IESGurdSyncStatusSuccess) forKey:IESGurdChannelPlaceHolder];
            } else {
                [self.statusDictionary setObject:@(IESGurdSyncStatusFailed) forKey:IESGurdChannelPlaceHolder];
            }
            if (self.completion) {
                self.completion(self.isSuccessful, [self.statusDictionary copy]);
            }
        }
        !block ? : block();
    });
}

@end
