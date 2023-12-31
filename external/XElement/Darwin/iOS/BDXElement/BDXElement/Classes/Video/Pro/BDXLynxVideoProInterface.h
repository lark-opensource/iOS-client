//
//  BDXLynxVideoProInterface.h
//
// Copyright 2022 The Lynx Authors. All rights reserved.
//

#ifndef BDXLynxVideoProInterface_h
#define BDXLynxVideoProInterface_h

@protocol BDXLynxVideoProPlayerProtocol

- (void)play;

- (void)stop;

- (void)pause;

- (void)mute:(BOOL)muted;

- (void)seek:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion;

@end

@protocol BDXLynxVideoProUIProtocol

- (void)fetchByResourceManager:(NSURL *)aURL
             completionHandler:(void (^)(NSURL *_Nonnull, NSURL *_Nonnull, NSError *_Nullable))completionHandler;

- (void)markPlay;

- (void)markStop;

- (void)markReady;

- (void)playerDidHitCache:(NSDictionary *)params;

- (void)playerDidPlay:(NSDictionary *)params;

- (void)playerDidLoopStop:(NSDictionary *)params;

- (void)playerDidStop:(NSDictionary *)params;

- (void)playerDidPause:(NSDictionary *)params;

- (void)playerBuffering:(NSDictionary *)params;

- (void)playerDidReady:(NSDictionary *)params;

- (void)playerDidTimeUpdate:(NSDictionary *)params;

- (void)playerDidRenderFirstFrame:(NSDictionary *)params;

- (void)didError:(NSNumber *)errCode msg:(NSString *)errMsg url:(NSString *)url;

@end


#endif /* BDXLynxVideoProInterface_h */
