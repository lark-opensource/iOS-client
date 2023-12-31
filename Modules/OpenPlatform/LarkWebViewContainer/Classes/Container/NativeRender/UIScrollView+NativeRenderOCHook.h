//
//  NativeRenderOCHook.h
//  LarkWebViewContainer
//
//  Created by tefeng liu on 2020/12/15.
//

#import <UIKit/UIKit.h>

@class NativeRenderObj;
@interface UIScrollView (NativeRenderOC)

@property (nonatomic, strong, nullable) NativeRenderObj *lkw_renderObject;

@property (nonatomic, strong, nullable) NativeRenderObj *lkw_syncRenderObject;

@end
