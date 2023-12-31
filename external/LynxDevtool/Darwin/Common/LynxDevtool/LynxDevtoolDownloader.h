// Copyright 2021 The Lynx Authors. All rights reserved.

typedef void (^downloadCallback)(NSData* _Nullable data, NSError* _Nullable error);

@interface LynxDevtoolDownloader : NSObject

+ (void)download:(NSString* _Nonnull)url withCallback:(downloadCallback _Nonnull)callback;

@end
