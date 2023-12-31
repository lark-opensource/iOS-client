//
//  UIScrollView+OKSnapshot.m
//  UITableViewSnapshotTest
//
//  Created by Tony on 2016/7/11.
//  Copyright © 2016年 TonyReet. All rights reserved.
//

#import "UIScrollView+OKSnapshot.h"
#import "OKScreenshotTools.h"
#import "UIView+OKSnapshot.h"
#import "OKSnapshotManager.h"

@implementation UIScrollView (OKSnapshot)

- (void )screenSnapshotNeedMask:(BOOL)needMask addMaskAfterBlock:(void(^)(void))addMaskAfterBlock finishBlock:(OKSnapshotFinishBlock )finishBlock{
    if (!finishBlock)return;
    
    UIView *snapshotMaskView;
    if (needMask){
        snapshotMaskView = [self addSnapshotMaskView];
        addMaskAfterBlock?addMaskAfterBlock():nil;
    }
    
    //保存原始信息
    __block CGPoint oldContentOffset;
    __block CGSize oldContentSize;
    
    onMainThreadSync(^{
        oldContentOffset = self.contentOffset;
        oldContentSize = self.contentSize;
    });

    // 异常判断，因为需要根据contentSize截取图片，如果width为0，取自身控件的宽度，结束后还原
    if (!self.contentSize.width){
        NSLog(@"width is zero");
        
        self.contentSize = CGSizeMake(self.bounds.size.width, self.contentSize.height);
    }
    
    // 使用拼接方案
    if ([OKSnapshotManager defaultManager].snapshotType == OKSnapshotTypeSplice){
        [self snapshotSpliceImageWith:snapshotMaskView contentSize:oldContentSize oldContentOffset:oldContentOffset finishBlock:finishBlock];
        return;
    }
    
    [self snapshotNormalImageWith:snapshotMaskView contentSize:oldContentSize oldContentOffset:oldContentOffset finishBlock:finishBlock];
}

- (void )snapshotNormalImageWith:(UIView *)snapshotMaskView contentSize:(CGSize )contentSize oldContentOffset:(CGPoint )oldContentOffset finishBlock:(OKSnapshotFinishBlock )finishBlock{
    //保存frame
    __block CGRect oldFrame;

    onMainThreadSync(^{
        oldFrame = self.layer.frame;
        // 划到bottom
        if (self.contentSize.height > self.frame.size.height) {
            self.contentOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom);
        }

        self.layer.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    });

    CGFloat delayTime = [OKSnapshotManager defaultManager].delayTime;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIImage* snapshotImage = nil;

        self.contentOffset = CGPointZero;

        UIGraphicsBeginImageContextWithOptions(self.layer.frame.size, NO, [UIScreen mainScreen].scale);

        CGContextRef context = UIGraphicsGetCurrentContext();

        [self.layer renderInContext:context];

        snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();

        //还原
        self.layer.frame = oldFrame;
        self.contentOffset = oldContentOffset;
        self.contentSize = contentSize;
        
        if (snapshotMaskView.layer){
            [snapshotMaskView.layer removeFromSuperlayer];
        }

        !finishBlock?:finishBlock(snapshotImage);
    });
}

- (instancetype )subScrollViewTotalExtraHeight:(void(^)(CGFloat subScrollViewExtraHeight))finishBlock{
    __block CGFloat extraHeight = 0.0;
    
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIScrollView class]]){
            UIScrollView *scrollView = (UIScrollView *)obj;
            
            if (scrollView.contentSize.height > scrollView.frame.size.height) {
                extraHeight = scrollView.contentSize.height - scrollView.frame.size.height;
            }
            
            [scrollView subScrollViewTotalExtraHeight:^(CGFloat subScrollViewExtraHeight) {
                extraHeight += subScrollViewExtraHeight;
            }];
        }
    }];
    
    
    finishBlock?finishBlock(extraHeight):nil;
    return self;
}
@end

