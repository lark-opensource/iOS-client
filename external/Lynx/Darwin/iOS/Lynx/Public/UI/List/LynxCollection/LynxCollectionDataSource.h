// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxCollectionViewCell;
@class LynxUIListLoader;
@class LynxUICollection;

@interface LynxCollectionDataSource : NSObject <UICollectionViewDataSource>
- (instancetype)initWithLynxUICollection:(LynxUICollection*)collection;
- (void)apply;
- (BOOL)applyFirstTime;
@property(nonatomic) BOOL ignoreLoadCell;
@end

NS_ASSUME_NONNULL_END
