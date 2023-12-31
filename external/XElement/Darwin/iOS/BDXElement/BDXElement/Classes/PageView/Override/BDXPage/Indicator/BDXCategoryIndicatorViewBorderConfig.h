//
//  BDXCategoryIndicatorViewBorderConfig.h
//  BDXElement
//
//  Created by hanzheng on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, BDXCategoryIndicatorViewBorderType) {
    BDXCategoryIndicatorViewBorderTypeTop = 1,
    BDXCategoryIndicatorViewBorderTypeBottom = 2,
};

@interface BDXCategoryIndicatorViewBorderConfig : NSObject

@property (nonatomic) BDXCategoryIndicatorViewBorderType borderType;

@property (nonatomic) BOOL hidden;

@property (nonatomic) CGFloat width;

@property (nonatomic) CGFloat height;

@property (nonatomic) CGFloat margin;

@property (nonatomic, strong) UIColor *color;

@end

NS_ASSUME_NONNULL_END
