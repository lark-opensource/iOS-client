//
//  CJPayDynamicLayoutModel.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2023/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDynamicLayoutModel : NSObject

// 进行页面动态高度布局时所需的布局属性
@property (nonatomic, assign) CGFloat topMargin; //上边界间距
@property (nonatomic, assign) CGFloat bottomMargin; //下边界间距（间距为正数）
@property (nonatomic, assign) CGFloat leftMargin; //左边界间距
@property (nonatomic, assign) CGFloat rightMargin; //右边界间距（间距为正数）
@property (nonatomic, assign) CGFloat forceHeight; //强制高度（需要限制高度或无法自撑开时使用）
@property (nonatomic, assign) CGFloat forceWidth; //强制宽度
@property (nonatomic, assign) BOOL useCenterX; //X轴居中对齐
@property (nonatomic, strong) NSArray<UIView *> *clickViews; //UI组件点击热区

- (instancetype)initModelWithTopMargin:(CGFloat)topMargin
                          bottomMargin:(CGFloat)bottomMargin
                          leftMargin:(CGFloat)leftMargin
                          rightMargin:(CGFloat)rightMargin;
@end

NS_ASSUME_NONNULL_END
