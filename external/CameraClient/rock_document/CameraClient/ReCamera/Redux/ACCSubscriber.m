//
//  ACCSubscriber.m
//  Pods
//
//  Created by leo on 2019/12/12.
//

#import "ACCSubscriber.h"

@interface ACCSubscriber ()
@property (nonatomic, copy) void (^next)(id value);
@end

@implementation ACCSubscriber

+ (instancetype)subscriberWithNext:(void (^)(id current))next
{
    ACCSubscriber *subscriber = [[self alloc] init];

    subscriber->_next = [next copy];
    return subscriber;
}

- (void)sendNext:(id)value
{
    @synchronized (self) {
        void (^nextBlock)(id) = [self.next copy];
        if (nextBlock == nil) return;

        nextBlock(value);
    }
}
@end
