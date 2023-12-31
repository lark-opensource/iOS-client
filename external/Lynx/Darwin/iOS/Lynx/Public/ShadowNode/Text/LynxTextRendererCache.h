// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTextRenderer.h"

NS_ASSUME_NONNULL_BEGIN

extern BOOL layoutManagerIsTruncated(NSLayoutManager *layoutManager);

@interface LynxTextRendererCache : NSObject <NSCacheDelegate>

+ (instancetype)cache;

- (instancetype)init NS_UNAVAILABLE;

- (LynxTextRenderer *)rendererWithString:(NSAttributedString *)str
                              layoutSpec:(LynxLayoutSpec *)spec;

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
