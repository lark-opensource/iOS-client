//
//  BDXLynxRefreshViewConfigInject.h
//  XElement
//
//  Created by Bytedance on 2021/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDXLynxRefreshViewInjectBlock)(UIScrollView *scrollView);

@protocol BDXLynxRefreshViewConfigInject <NSObject>

@required
- (void)refreshViewInjection:(BDXLynxRefreshViewInjectBlock)injection;

@end

NS_ASSUME_NONNULL_END
