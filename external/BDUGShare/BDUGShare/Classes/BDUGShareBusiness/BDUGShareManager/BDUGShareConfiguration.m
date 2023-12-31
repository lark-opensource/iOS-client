//
//  BDUGShareConfiguration.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/10/22.
//

#import "BDUGShareConfiguration.h"

@implementation BDUGShareConfiguration

+ (instancetype)defaultConfiguration
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _localMode = NO;
        _hostString = @"https://i.snssdk.com/";
    }
    return self;
}

- (void)setHostString:(NSString *)hostString {
    if (![hostString hasSuffix:@"/"]) {
        //增加 / 后缀。
        hostString = [NSString stringWithFormat:@"%@/", hostString];
    }
    _hostString = hostString;
}

@end
