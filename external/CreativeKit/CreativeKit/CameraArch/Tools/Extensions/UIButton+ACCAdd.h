//
//  UIButton+ACCAdd.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCButtonImageLayout) {
    ACCButtonImageLayoutTop,
    ACCButtonImageLayoutLeft,
    ACCButtonImageLayoutBottom,
    ACCButtonImageLayoutRight
};

@interface UIButton (ACCAdd)

- (void)acc_fitWithImageLayout:(ACCButtonImageLayout)layoyt space:(CGFloat)space;

@end

NS_ASSUME_NONNULL_END
