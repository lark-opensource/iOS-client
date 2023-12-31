//
//  WKWebView+OKSnapshot.m
//  OKSnapshotScroll
//
//  Created by apple on 16/12/28.
//  Copyright © 2016年 TonyReet. All rights reserved.
//

#import "WKWebView+OKSnapshot.h"
#import "OKScreenshotTools.h"
#import "UIView+OKSnapshot.h"
#import "OKSnapshotManager.h"
#import "UIScrollView+OKSnapshot.h"

@implementation WKWebView (OKSnapshot)

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
    __block CGSize contentSize;
    __block UIScrollView *scrollView;
    
    onMainThreadSync(^{
        scrollView = self.scrollView;
        
        oldContentOffset = scrollView.contentOffset;
        oldContentSize = scrollView.contentSize;
        contentSize = oldContentSize;
        contentSize.height += scrollView.contentInset.top + scrollView.contentInset.bottom;
    });
    
//    if ([scrollView isBigImageWith:contentSize]){
//        [scrollView snapshotBigImageWith:snapshotMaskView contentSize:contentSize oldContentOffset:oldContentOffset finishBlock:finishBlock];
//        return ;
//    }

    [scrollView snapshotSpliceImageWith:snapshotMaskView contentSize:contentSize oldContentOffset:oldContentOffset finishBlock:finishBlock];
}
@end
