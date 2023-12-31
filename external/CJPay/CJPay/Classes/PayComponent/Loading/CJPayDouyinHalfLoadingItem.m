//
//  CJPayDouyinHalfLoadingItem.m
//  Pods
//
//  Created by 易培淮 on 2021/8/17.
//

#import "CJPayDouyinHalfLoadingItem.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySettings.h"

@implementation CJPayDouyinHalfLoadingItem

@synthesize delegate = _delegate;

- (void)startAnimation {
    [self.imageView cj_loadGifAndInfinityLoop:@"cj_new_loading_gif" duration:1.3];
}

- (NSString *)loadingTitle {
    return CJPayDYPayTitleMessage;
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeDouyinHalfLoading;
}

@end
