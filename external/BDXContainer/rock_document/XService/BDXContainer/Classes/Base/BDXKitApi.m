//
// Created by duanefaith on 2019/10/12.
//

#import "BDXKitApi.h"

@implementation BDXKitApi

- (instancetype)initWithContext:(BDXContext *)context
{
    self = [super init];
    if (self) {
        self.context = context;
    }

    return self;
}

- (UIView<BDXKitViewProtocol> *)provideKitViewWithURL:(NSURL *)url
{
    return nil;
}

@end
