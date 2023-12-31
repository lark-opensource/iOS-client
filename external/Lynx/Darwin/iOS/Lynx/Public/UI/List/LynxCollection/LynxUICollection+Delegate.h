// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxListScrollEventEmitter.h"
#import "LynxUICollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUICollection (Delegate) <UICollectionViewDelegate,
                                        LynxListScrollEventEmitterDelegate>
- (void)sendLayoutCompleteEvent;
@end

NS_ASSUME_NONNULL_END
