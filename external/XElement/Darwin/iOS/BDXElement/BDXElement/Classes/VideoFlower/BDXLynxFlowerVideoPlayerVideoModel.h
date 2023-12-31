// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXLynxFlowerVideoPlayerAPIVersion) {
  BDXLynxFlowerVideoPlayerAPIVersion1,
  BDXLynxFlowerVideoPlayerAPIVersion2,
};

@interface BDXLynxFlowerVideoPlayerVideoModel : NSObject

@property(nonatomic, assign) BOOL isCanPlay;  // allow to play
@property(nonatomic, copy) NSString *itemID;
@property(nonatomic, copy) NSString *playUrlString;
@property(nonatomic, assign) BOOL repeated;  // default NO
@property(nonatomic, copy) NSString *customhost;
@property(nonatomic, copy) NSString *playAutoToken;
@property(nonatomic, copy) NSString *playerVersion;
@property(nonatomic, copy) NSString *protocolVer;
@property(nonatomic, strong) NSArray<NSString *> *hosts;

@property(nonatomic, assign) BDXLynxFlowerVideoPlayerAPIVersion apiVersion;

@end

NS_ASSUME_NONNULL_END
