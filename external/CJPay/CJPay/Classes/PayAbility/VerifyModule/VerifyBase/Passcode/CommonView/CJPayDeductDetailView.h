//
//  CJPayDeductDetailView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDeductDetailView : UIView

- (void)updateDeductDetailWithTitleArray:(NSArray<NSString *> *)titleArray descArray:(NSArray<NSString *> *)descArray isDescHighLightArray:(NSArray<NSNumber *> *)isDescHighLightArray;

@end

NS_ASSUME_NONNULL_END
