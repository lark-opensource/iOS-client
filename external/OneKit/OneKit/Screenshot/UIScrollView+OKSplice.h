//
//  UIScrollView+TYSplice.h
//  Pods-OKSnapshotScrollDemo
//
//  Created by tonyreet on 2020/8/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^OKSnapshotFinishBlock)(UIImage *snapshotImage);

@interface UIScrollView (OKSplice)

- (void )snapshotSpliceImageWith:(UIView *)snapshotMaskView contentSize:(CGSize )contentSize oldContentOffset:(CGPoint )oldContentOffset finishBlock:(OKSnapshotFinishBlock )finishBlock;

- (void )snapshotSpliceImageWith:(UIView *)snapshotMaskView contentSize:(CGSize )contentSize oldContentSize:(CGSize )oldContentSize oldContentOffset:(CGPoint )oldContentOffset finishBlock:(OKSnapshotFinishBlock )finishBlock;

@end

NS_ASSUME_NONNULL_END
