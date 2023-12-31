//
//  BDNativeWebContainerView.m
//  AFgzipRequestSerializer
//
//  Created by liuyunxuan on 2019/6/3.
//

#import "BDNativeWebContainerView.h"

@interface BDNativeWebContainerView()

@property (nonatomic, copy) BDNativeContainerBeRemovedAction nativeRemoveAction;

@end

@implementation BDNativeWebContainerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    if (self.nativeRemoveAction) {
        self.nativeRemoveAction();
    }
}

- (void)configNativeContainerBeRemovedAction:(BDNativeContainerBeRemovedAction)action
{
    self.nativeRemoveAction = action;
}

- (void)dealloc
{
    
}
@end
