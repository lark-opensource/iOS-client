// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

#if OS_IOS
#import <Lynx/LynxClassAliasDefines.h>
#elif OS_OSX
#import <LynxMacOS/LynxClassAliasDefines.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol FrameCapturerDelegate

@required
- (BOOL)isEnabled;
- (NSString*)takeSnapshot:(VIEW_CLASS*)view;
- (void)onNewSnapshot:(NSString*)data;
- (void)onFrameChanged;

@end

@interface LynxDevtoolFrameCapturer : NSObject

- (void)attachView:(VIEW_CLASS*)uiView;
- (void)startFrameViewTrace;
- (void)stopFrameViewTrace;
- (void)screenshot;

@property(nonatomic, weak, readwrite, nullable) VIEW_CLASS* uiView;
@property(nonatomic, readwrite, nullable) NSString* snapshotCache;
@property(nonatomic, readwrite) uint64_t snapshotInterval;
@property(nonatomic, readwrite) uint64_t lastScreenshotTime;
@property(nonatomic, readwrite, nullable) CFRunLoopObserverRef observer;
@property(atomic, readwrite) BOOL hasSnapshotTask;

@property(nonatomic, weak, readwrite, nullable) id<FrameCapturerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
