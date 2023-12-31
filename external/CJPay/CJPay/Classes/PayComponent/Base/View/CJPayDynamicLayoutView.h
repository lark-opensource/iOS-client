//
//  CJPayDynamicLayoutView.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2023/4/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayDynamicLayoutViewDelegate <NSObject>

@optional
- (void)dynamicViewFrameChange:(CGRect)newFrame; //更新bounds时通知delegate

@end

// 基于stackView实现的动态化布局UI组件
@interface CJPayDynamicLayoutView : UIStackView

@property (nonatomic, weak) id<CJPayDynamicLayoutViewDelegate> delegate;
// contentViews为参与动态布局的UIVIew集合，每个UIView都应保证能撑开高度并且初始化cj_dynamicLayoutModel
- (void)updateWithContentViews:(NSArray<UIView *> *)contentViews isLayoutInstantly:(BOOL)layoutInstantly;
// 新增参与动态布局的subView（加在尾部）
- (void)addDynamicLayoutSubview:(UIView *)view;
// 新增参与动态布局的subView（根据索引插入）
- (void)insertDynamicLayoutSubview:(UIView *)view atIndex:(NSUInteger)stackIndex;
// 移除参与动态布局的subView
- (void)removeDynamicLayoutSubview:(UIView *)view;
// 修改参与动态布局的subViews显隐状态
- (void)setDynamicLayoutSubviewHiddenStatus:(NSArray<UIView *> *)subviews;
@end

NS_ASSUME_NONNULL_END
