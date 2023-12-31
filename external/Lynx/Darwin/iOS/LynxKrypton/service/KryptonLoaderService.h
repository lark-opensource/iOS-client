//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonService.h"

NS_ASSUME_NONNULL_BEGIN

/// Loader callback block.
/// Can be called in any thread.
///
/// The first argument is error message, pass `nil` if no error happened.
/// The second argument is data of the load request.
typedef void (^KryptonLoaderCallback)(NSString *_Nullable err, NSData *_Nullable data);

/// Loader deletate
@protocol KryptonStreamLoadDelegate <NSObject>
@required
/// Load process started
/// @param contentLength total length or -1 means unknown
- (void)onStart:(NSInteger)contentLength;
// Load process return part of data
/// @param data
/// May be called once or more
- (void)onData:(nullable NSData *)data;
/// Load process ended
- (void)onEnd;
/// Load ended with error
- (void)onError:(nullable NSString *)msg;
@end

@protocol KryptonLoaderService <KryptonService>

@required
/// Load url asynchronously. Load url asynchronously with delegate. The data is returned multiple
/// times.
/// @param url remote or local url.
/// @param callback callback block.
- (void)loadURL:(nullable NSString *)url callback:(nonnull KryptonLoaderCallback)callback;

/// Redirect to real url
/// @param url emote or local url.
- (NSString *)redirectURL:(nullable NSString *)url;

@optional
/// Load url asynchronously with delegate. The data is streamly returned.
/// @param url remote or local url.
/// @param delegate delegate for stream load.
- (void)loadURL:(nullable NSString *)url
    withStreamLoadDelegate:(nonnull id<KryptonStreamLoadDelegate>)delegate;

/// Decode image data
/// @param data
- (UIImage *)loadImageData:(NSData *)data;

/// Report image track event
/// @param data
- (void)reportLoaderTrackEvent:(NSString *)eventName format:(NSString *)format data:(id)formatData;

@end

NS_ASSUME_NONNULL_END
