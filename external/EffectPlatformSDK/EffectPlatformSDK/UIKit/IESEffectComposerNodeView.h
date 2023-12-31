//
//  IESEffectComposerNodeView.h
//  Pods
//
//  Created by stanshen on 2018/9/29.
//

#import <UIKit/UIKit.h>

#import "IESComposerModel.h"

@class IESEffectComposerNodeView;
@protocol IESEffectComposerNodeViewDelegate <NSObject>

- (void)backButtonTappedForComposerNodeView:(IESEffectComposerNodeView *)nodeView;
- (void)composerNodeView:(IESEffectComposerNodeView *)nodeView didSelectAtIndexPath:(NSIndexPath *)indexPath;
- (void)composerNodeView:(IESEffectComposerNodeView *)nodeView didChangeSliderValue:(float)sliderValue;

@end

@interface IESEffectComposerNodeView : UIView

@property (nonatomic, weak) id<IESEffectComposerNodeViewDelegate> delegate;
- (void)updateWithComposerModel:(IESComposerModel *)model; // 根据composer数据更新View显示

@end
