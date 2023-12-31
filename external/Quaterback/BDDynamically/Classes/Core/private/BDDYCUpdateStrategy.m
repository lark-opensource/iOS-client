//
//  BDDYCUpdateStrategy.m
//  BDDynamically
//
//  Created by zuopengliu on 10/10/18.
//

#import "BDDYCUpdateStrategy.h"



typedef void (^BDDYCUpdateStrategyBlock)(void);

@interface BDDYCUpdateStrategy ()
@property (nonatomic, copy) BDDYCUpdateStrategyBlock handler;
@end

@implementation BDDYCUpdateStrategy

- (instancetype)initWithUpdateNotifier:(void (^)(void))handler
{
    if ((self = [super init])) {
        _handler = handler;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)applicationWillEnterForeground:(id)note
{
    if (_handler) _handler();
}

@end
