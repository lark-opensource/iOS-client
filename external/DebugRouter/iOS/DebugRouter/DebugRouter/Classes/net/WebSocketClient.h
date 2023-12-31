#import "MessageTransceiver.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebSocketClient : MessageTransceiver

@property(nonatomic, readwrite, nullable) void *cronet_engine;

- (BOOL)connect:(NSString *)url;
- (void)disconnect;
- (void)reconnect;
- (void)send:(id)data;

@end

NS_ASSUME_NONNULL_END
