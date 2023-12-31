#import <Foundation/Foundation.h>

@class MessageTransceiver;
@protocol MessageTransceiverDelegate <NSObject>

@required
- (void)onOpen:(MessageTransceiver *)transceiver;
- (void)onClosed:(MessageTransceiver *)transceiver;
- (void)onFailure:(MessageTransceiver *)transceiver;
- (void)onMessage:(id)message fromTransceiver:(MessageTransceiver *)transceiver;

@end

@interface MessageTransceiver : NSObject

@property(nonatomic, readwrite) id<MessageTransceiverDelegate> delegate_;

- (BOOL)connect:(NSString *)url;
- (void)disconnect;
- (void)reconnect;
- (void)send:(id)data;
- (void)handleReceivedMessage:(id)message;
@end
