//
//  UIViewController+ADFGPageMonitor.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/11.
//

#import <UIKit/UIKit.h>

typedef void(^ADFGViewDidDisappear)(BOOL animation);

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (ADFGPageMonitor)

@property (nonatomic, copy) ADFGViewDidDisappear adfgViewDidDisappearBlock;

+ (void)setupSwizzleMethod;

@end

NS_ASSUME_NONNULL_END
