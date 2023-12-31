//
//  BDXElementAdapter.m
//  BDXElement
//
//  Created by miner on 2020/7/13.
//

#import "BDXElementAdapter.h"

@implementation BDXElementAdapter

+ (instancetype)sharedInstance
{
    static BDXElementAdapter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BDXElementAdapter new];
    });
    return instance;
}

@end

@implementation BDXElementAdapter (Deprecated)

- (void)setLottieDelegate:(id<BDXElementLottieDelegate>)lottieDelegate
{
    self.monitorDelegate = lottieDelegate;
}

- (id<BDXElementLottieDelegate>)lottieDelegate
{
    return (id<BDXElementLottieDelegate>)self.monitorDelegate;
}

@end
