//
//  ACCDuetAmountView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/26.
//

#import <UIKit/UIKit.h>


@interface ACCDuetAmountView : UIView

@property (nonatomic, copy, nonnull) NSString *text;

+ (NSString *)usageAmountString:(NSInteger)amount;

@end

