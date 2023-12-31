//
//  TMAVideoContainer.m
//  OPPluginBiz
//
//  Created by tujinqiu on 2020/2/3.
//

#import "TMAVideoContainer.h"

@interface _TMAVideoPlayerHolder : NSObject

@property (nonatomic, weak) id<TMAVideoContainerPlayerDelegate> player;

@end

@implementation _TMAVideoPlayerHolder

@end

@interface TMAVideoContainer ()

@property (nonatomic, strong) NSMutableArray<_TMAVideoPlayerHolder *> *holdersArr;

@end

@implementation TMAVideoContainer

+ (instancetype)sharedContainer
{
    static TMAVideoContainer *conatiner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        conatiner = [TMAVideoContainer new];
    });
    return conatiner;
}

- (instancetype)init
{
    if (self = [super init]) {
        _holdersArr = [NSMutableArray new];
    }
    return self;
}

- (void)addPlayer:(id<TMAVideoContainerPlayerDelegate>)player
{
    if (!player) {
        return;
    }
    _TMAVideoPlayerHolder *holder = [_TMAVideoPlayerHolder new];
    holder.player = player;
    [self.holdersArr addObject:holder];
}

- (void)closeAll
{
    for (_TMAVideoPlayerHolder *holder in self.holdersArr) {
        if ([holder.player respondsToSelector:@selector(close)]) {
            [holder.player close];
        }
    }
    [self.holdersArr removeAllObjects];
}

@end
