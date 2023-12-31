//
//  UIScrollView+OKSnapshot.h
//  UITableViewSnapshotTest
//
//  Created by Tony on 2016/7/11.
//  Copyright © 2016年 TonyReet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+OKSplice.h"

@interface UIScrollView (OKSnapshot)


- (void )screenSnapshotNeedMask:(BOOL)needMask addMaskAfterBlock:(void(^)(void))addMaskAfterBlock finishBlock:(OKSnapshotFinishBlock )finishBlock;

// 是否是大图
//- (BOOL )isBigImageWith:(CGSize )contentSize;
//
//// 截图大图
//- (void )snapshotBigImageWith:(UIView *)snapshotMaskView contentSize:(CGSize )contentSize oldContentOffset:(CGPoint )oldContentOffset finishBlock:(OKSnapshotFinishBlock )finishBlock;

/// 获取子scrollView的内容的多余高度
/// @param finishBlock 结束回调
- (instancetype )subScrollViewTotalExtraHeight:(void(^)(CGFloat subScrollViewExtraHeight))finishBlock;
@end

