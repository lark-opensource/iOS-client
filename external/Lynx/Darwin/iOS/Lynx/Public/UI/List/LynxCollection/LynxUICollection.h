// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxUIListLoader.h"
#import "LynxUIListScrollEvent.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LynxListVerticalOrientation) {
  LynxListOrientationNone,
  LynxListOrientationVertical,
  LynxListOrientationHorizontal,
};

// TODO(hujing.1): move other place from the public folder
@interface LynxUICollection : LynxUIListLoader <UICollectionView *> <LynxUIListScrollEvent>

@property(nonatomic, assign) BOOL noRecursiveLayout;
@property(nonatomic, assign) BOOL forceReloadData;
@property(nonatomic, strong) NSMutableDictionary *listNativeStateCache;
@property(nonatomic) LynxListVerticalOrientation verticalOrientation;

// the switch is used for async-list
@property(nonatomic) BOOL enableAsyncList;
// checks if list can render components on next step;
- (BOOL)isNeedRenderComponents;

@end
NS_ASSUME_NONNULL_END
