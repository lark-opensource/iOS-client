//
//  ACCMvAmountView.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/7/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMvAmountView : UIView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *amountLabelFont; // default is 11pt, medium;

+ (NSString *)usageAmountString:(NSUInteger)amount;

@end

NS_ASSUME_NONNULL_END
