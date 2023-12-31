//
//  CJPayBaseLoadingItem.m
//  Pods
//
//  Created by 易培淮 on 2021/9/1.
//

#import "CJPayBaseLoadingItem.h"

@implementation CJPayBaseLoadingItem

@synthesize delegate = _delegate;

- (void)resetLoadingCount {
    if (self.delegate && [self.delegate respondsToSelector:@selector(resetLoadingCount:)]) {
        [self.delegate resetLoadingCount:[[self class] loadingType]];
    }
}

- (void)addLoadingCount {
    if (self.delegate && [self.delegate respondsToSelector:@selector(addLoadingCount:)]) {
        [self.delegate addLoadingCount:[[self class] loadingType]];
    }
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeTopLoading;
}

@end
