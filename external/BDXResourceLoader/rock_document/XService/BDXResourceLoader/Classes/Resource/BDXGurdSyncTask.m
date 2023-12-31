//
//  BDXGurdSyncTask.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import "BDXGurdSyncTask.h"

NSString *const kBDXGurdHighPriorityGroupName = @"high_priority";
NSString *const kBDXGurdNormalGroupName = @"normal";

static NSString *const kBDXGurdDefaultGroupName = @"default";

static NSUInteger BDXGurdSyncTaskHashForArray(NSArray *array);

@implementation BDXGurdSyncResourcesResult

@end

@interface BDXGurdSyncTask ()

@property(nonatomic, readwrite, copy) NSString *accessKey;

@property(nullable, nonatomic, readwrite, copy) NSArray<NSString *> *channelsArray;

@property(nullable, nonatomic, readwrite, copy) NSString *groupName;

@property(nullable, nonatomic, readwrite, copy) BDXGurdSyncTaskCompletion completion;

@property(atomic, readwrite, assign) BDXGurdSyncTaskState state;

@property(nullable, nonatomic, strong) NSLock *allCompletionsLock;
@property(nullable, nonatomic, strong) NSMutableArray<BDXGurdSyncTaskCompletion> *allCompletions;

@end

@implementation BDXGurdSyncTask

+ (instancetype)taskWithAccessKey:(NSString *_Nonnull)accessKey groupName:(NSString *_Nullable)groupName channelsArray:(NSArray<NSString *> *_Nullable)channelsArray completion:(BDXGurdSyncTaskCompletion _Nullable)completion
{
    BDXGurdSyncTask *task = [[self alloc] init];
    task.accessKey = accessKey;
    task.groupName = groupName ?: kBDXGurdDefaultGroupName;
    task.channelsArray = channelsArray ?: @[];
    task.allCompletionsLock = [NSLock new];
    task.allCompletions = completion ? [NSMutableArray arrayWithObject:completion] : [NSMutableArray array];
    task.downloadPriority = BDXGurdDownloadPriorityHigh;
    return task;
}

- (void)addCompletionOfTask:(BDXGurdSyncTask *)task
{
    if (task.allCompletions.count > 0) {
        [self.allCompletionsLock lock];
        [self.allCompletions addObjectsFromArray:task.allCompletions];
        [self.allCompletionsLock unlock];
    }
}

- (void)callCompletionsWithResult:(BDXGurdSyncResourcesResult *)result
{
    if (self.allCompletions.count > 0) {
        [self.allCompletionsLock lock];
        [self.allCompletions enumerateObjectsUsingBlock:^(BDXGurdSyncTaskCompletion obj, NSUInteger idx, BOOL *stop) {
            obj(result);
        }];
        [self.allCompletions removeAllObjects];
        [self.allCompletionsLock unlock];
    }
}

#pragma mark - Equality

// https://nshipster.com/equality/

- (BOOL)isEqual:(id)other
{
    if (self == other) {
        return YES;
    }
    if (![other isKindOfClass:[BDXGurdSyncTask class]]) {
        return NO;
    }
    return [self isEqualToTask:(BDXGurdSyncTask *)other];
}

- (NSUInteger)hash
{
    return [self.accessKey hash] ^ [self.groupName hash] ^ BDXGurdSyncTaskHashForArray(self.channelsArray);
}

- (BOOL)isEqualToTask:(BDXGurdSyncTask *)otherTask
{
    if (![self.accessKey isEqualToString:otherTask.accessKey]) {
        return NO;
    }
    if (![self.groupName isEqualToString:otherTask.groupName]) {
        return NO;
    }
    return ([[NSSet setWithArray:self.channelsArray] isEqualToSet:[NSSet setWithArray:otherTask.channelsArray]]);
}

#pragma mark - Getter

- (BOOL)isExecuting
{
    return self.state == BDXGurdSyncTaskStateExecuting;
}

- (BOOL)forceRequest
{
    return self.options & BDXGurdSyncResourcesOptionsForceRequest;
}

@end

// https://stackoverflow.com/a/254380
NSUInteger BDXGurdSyncTaskHashForArray(NSArray *array)
{
    NSUInteger result = 1;
    NSUInteger prime = 31;
    NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *object in sortedArray) {
        result = prime * result + [object hash];
    }
    return result;
}
