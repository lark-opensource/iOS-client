//
//  UIView+OKSnapshot.m
//  OKSnapshotScrollDemo
//
//  Created by TonyReet on 2019/3/26.
//  Copyright © 2019 TonyReet. All rights reserved.
//

#import "UIView+OKSnapshot.h"
#import "UIViewController+OKSnapshot.h"
#import "OKScreenshotTools.h"

@implementation UIView (OKSnapshot)

- (void )screenSnapshotNeedMask:(BOOL)needMask addMaskAfterBlock:(void(^)(void))addMaskAfterBlock finishBlock:(void(^)(UIImage *snapshotImage))finishBlock{
    if (!finishBlock)return;
    
    UIView *snapshotMaskView;
    if (needMask){
      snapshotMaskView = [self addSnapshotMaskView];
      addMaskAfterBlock?addMaskAfterBlock():nil;
    }
    
    UIImage *snapshotImage = nil;
    
    __block CGRect bounds;
    __block CALayer *selfLayer;
    onMainThreadSync(^{
        bounds = self.bounds;
        selfLayer = self.layer;
    });
    
    UIGraphicsBeginImageContextWithOptions(bounds.size,NO,[UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [selfLayer renderInContext:context];

    snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    if (snapshotMaskView){
        [snapshotMaskView removeFromSuperview];
    }

    finishBlock(snapshotImage);
}


- (UIView *)addSnapshotMaskView{
    __block UIView *snapshotMaskView;
    
    //获取父view
    __block UIView *superview;
    __block UIViewController *currentViewController;
    
    onMainThreadSync(^{
        currentViewController = [UIViewController currentViewController];
        if (currentViewController){
            superview = currentViewController.view;
        }else{
            superview = self.superview;
        }
        
        //添加遮盖
        snapshotMaskView = [superview snapshotViewAfterScreenUpdates:YES];
        
        snapshotMaskView.frame = superview.frame;
        [superview.layer addSublayer:snapshotMaskView.layer];
    });
    
    return snapshotMaskView;
}
@end
