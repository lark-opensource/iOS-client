//
//  BDNativeWebLogManager.m
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/7/30.
//

#import "BDNativeWebLogManager.h"

@interface BDNativeWebLogManager()

@property (nonatomic, strong) BDNativeLogBolock logBlock;

@end

@implementation BDNativeWebLogManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDNativeWebLogManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)configLogBlock:(BDNativeLogBolock)logBlock
{
    self.logBlock = logBlock;
}

- (void)printLog:(NSString *)log
{
    if (self.logBlock)
    {
        self.logBlock(log);
    }
}
@end
