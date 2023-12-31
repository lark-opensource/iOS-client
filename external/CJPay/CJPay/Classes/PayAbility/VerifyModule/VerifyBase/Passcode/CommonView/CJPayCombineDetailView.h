//
//  CJPayCombineDetailView.h
//  Pods
//
//  Created by liutianyi on 2022/5/23.
//

#import <Foundation/Foundation.h>
@class BDPayCombinePayShowInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCombineDetailView : UIView

- (void)updateWithCombineShowInfo:(NSArray<BDPayCombinePayShowInfo *> *)combineShowInfo;

@end

NS_ASSUME_NONNULL_END
