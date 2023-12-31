//
//  LKNativeRenderDelegate.h
//  LarkWebViewContainer
//
//  Created by baojianjun on 2022/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RenderState;
@protocol LKNativeRenderDelegate <NSObject>

@property (nonatomic, strong) RenderState *renderState;

- (void)lk_render;

@end

NS_ASSUME_NONNULL_END
