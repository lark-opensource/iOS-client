//
//  UIView+CJLayout.h
//  AFNetworking
//
//  Created by jiangzhongping on 2018/8/17.
//

#import <UIKit/UIKit.h>

@class CJPayDynamicLayoutModel;
@interface UIView (CJLayout)

@property (nonatomic, assign) CGFloat cj_left;
@property (nonatomic, assign) CGFloat cj_top;
@property (nonatomic, assign) CGFloat cj_right;
@property (nonatomic, assign) CGFloat cj_bottom;
@property (nonatomic, assign) CGFloat cj_width;
@property (nonatomic, assign) CGFloat cj_height;
@property (nonatomic, assign) CGSize  cj_size;
@property (nonatomic, assign) CGFloat cj_centerX;
@property (nonatomic, assign) CGFloat cj_centerY;

@property (nonatomic, strong) CJPayDynamicLayoutModel *cj_dynamicLayoutModel; // 此UIView进行页面动态高度布局时所需的布局属性

@end
