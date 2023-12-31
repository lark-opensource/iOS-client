//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//TODO:This protocol can be removed after TT all changed to ACCViewController
@protocol ACCUIViewControllerProtocol <NSObject>

@property (nonatomic, strong, readonly) UIView *view;

@end

NS_ASSUME_NONNULL_END
