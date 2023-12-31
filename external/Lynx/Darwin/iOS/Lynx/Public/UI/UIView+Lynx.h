// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Lynx)

@property(nonatomic, copy) NSNumber *lynxSign;

@property(nonatomic, readwrite) BOOL lynxClickable;

@end

NS_ASSUME_NONNULL_END
