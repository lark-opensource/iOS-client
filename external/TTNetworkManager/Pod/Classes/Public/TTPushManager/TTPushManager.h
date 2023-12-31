//
//  TTPushManager.h
//  TTPushManager
//
//  Created by gaohaidong on 4/25/16.
//  Copyright © 2016 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTPushMessageBaseObject.h"

NS_ASSUME_NONNULL_BEGIN
// ByteDance WiKi: pages/viewpage.action?pageId=60293367
// Google Doc: document/d/1IDjl5u1lOEWHtgyHl4NY7hkhVllbKpHqohf0mpm4vms/edit#heading=h.ahup5cvuecw3

@interface TTPushConfig : NSObject
/*!
 * @brief The application id.
 * (Must Have)
 */
@property (nonatomic, assign) int32_t appId;
/*!
 * @brief The frontier product id.
 * (Must Have)
 * See this for detail: Google Doc: document/d/1IDjl5u1lOEWHtgyHl4NY7hkhVllbKpHqohf0mpm4vms/edit#heading=h.ahup5cvuecw3
 */
@property (nonatomic, assign) int32_t fpid;
/*!
 * @brief The device id.
 * (Must Have)
 */
@property (nonatomic, assign) int64_t deviceId;
/*!
 * @brief The app version.
 * (Must Have)
 */
@property (nonatomic, assign) int32_t appVersion;
/*!
 * @brief The app install id.
 * (Better Have)
 */
@property (nonatomic, assign) int64_t installId;

/*!
 * @brief Not used.
 *
 */
@property (nonatomic, assign) int64_t webId;
/*!
 * @brief The device platfom.
 * (Must Have)
 0: android
 1: iphone
 4: ipad
 8: wap
 */
@property (nonatomic, assign) int32_t platform;
/*!
 * @brief The network type.
 * (Must Have)
 0: unknown
 1: wifi
 2: 2G
 3: 3G
 4: 4G
 */
@property (nonatomic, assign) int32_t network;
/*!
 * @brief Report the app state to frontier.
 *
 */
@property(nonatomic, assign) BOOL enableAppStateReport;
/*!
 * @brief The application key.
 * (Must Have)
 */
@property (nonatomic, copy) NSString *appKey;
/*!
 * @brief The app session id(login related)
 * (Better Have)
 */
@property (nullable, nonatomic, copy) NSString *sessionId;
/*!
 * @brief self defined query parameters, must be url encoded value
 *
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSString *> *customParams;
/*!
 * @brief self defined query header
 *
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSString *> *customHeaders;
/*!
 * @brief The frontier urls. Such as: @"wss://your.domain.com/ws/v2"
 * (Must Have)
 */
@property (nonatomic, copy) NSArray<NSString *> *urls;
@end

//@class PushMessageBaseObject;
@class TTPushMessageReceiver;

/*!
 * @brief Notification when receiving unknown push message.
 *
 */
extern NSString * const kTTPushManagerUnknownPushMessage;
extern NSString * const kTTPushManagerUnknownPushMessageUserInfoKey;

/*!
 * @brief Notification when receiving a push message via frontier by default.
 *
 */
extern NSString * const kTTPushManagerOnReceivingMessage;
extern NSString * const kTTPushManagerOnReceivingMessageUserInfoKey;

/*!
 * @brief Notification when receiving a push message via wschannel.
 *
 */
extern NSString * const kTTPushManagerOnReceivingWSChannelMessage;
extern NSString * const kTTPushManagerOnReceivingWSChannelMessageUserInfoKey;

/*!
 * @brief Notification when receiving feedback log via wschannel.
 *
 */
extern NSString * const kTTPushManagerOnFeedbackLog;
extern NSString * const kTTPushManagerOnFeedbackLogUserInfoKey;

/*!
 * @brief Notification when connection error occured.
 *
 */
extern NSString * const kTTPushManagerConnectionError;
extern NSString * const kTTPushManagerConnectionErrorUserInfoKeyURL;
extern NSString * const kTTPushManagerConnectionErrorUserInfoKeyConnectionState;
extern NSString * const kTTPushManagerConnectionErrorUserInfoKeySpecificError;

/*!
 * @brief Notification when connection state changed.
 *
 */
extern NSString * const kTTPushManagerConnectionStateChanged;
extern NSString * const kTTPushManagerConnectionStateChangedInfoKeyConnectionState;
extern NSString * const kTTPushManagerConnectionStateChangedInfoKeyURL;

/*!
 * @brief Notification when received a message.
 *
 */
extern NSString * const kTTPushManagerOnTrafficChanged;
extern NSString * const kTTPushManagerOnTrafficChangedUserInfoKeyURL;
extern NSString * const kTTPushManagerOnTrafficChangedUserInfoKeySentBytes;
extern NSString * const kTTPushManagerOnTrafficChangedUserInfoKeyReceivedBytes;
extern NSString * const kTTPushManagerOnTrafficChangedUserInfoKeyIsHeartBeatFrame;

typedef NS_ENUM(NSUInteger, TTPushManagerNetworkState) {
    TTPushManagerNetworkState_ReachableUnKnown,
    TTPushManagerNetworkState_NotReachable,
    TTPushManagerNetworkState_ReachableViaWiFi,
    TTPushManagerNetworkState_ReachableViaWWAN,
};

typedef NS_ENUM(NSUInteger, TTPushManagerConnectionState) {
    TTPushManagerConnectionState_ConnectUnknown,
    TTPushManagerConnectionState_Connecting,
    TTPushManagerConnectionState_ConnectFailed,// there were errors when trying to connect the server
    TTPushManagerConnectionState_ConnectClosed,// the connection was connected before, but closed due to some reason
    TTPushManagerConnectionState_Connected,
    TTPushManagerConnectionState_Disconnecting,
};

typedef NS_ENUM(NSUInteger, TTPushManagerMessageType) {
    TTPushManagerMessageType_Unknown,
    TTPushManagerMessageType_Text,
    TTPushManagerMessageType_Binary,
};

typedef NS_ENUM(NSUInteger, TTPushManagerConnectionMode) {
    TTPushManagerConnectionMode_Frontier, // Use frontier protocol to build connection.
    TTPushManagerConnectionMode_WSChannel, // Use original interface of websocket channel to build connection.
};

@protocol WsDelegate;

@interface TTPushManager : NSObject
/*！
 * The delegate of the web socket, only support for TTPushManagerConnectionMode_WSChannel mode.
 * The web socket delegate is notified on all state changes that happen to the web socket.
 */
@property (nonatomic, weak) id <WsDelegate> delegate;

/*!
* @discussion Get the default push manager singleton instance.
* @return The the default push manager singleton instance.
*/
+ (instancetype)sharedManager;
/*!
 * @discussion Get the second push manager singleton instance.
 * @return The the second push manager singleton instance.
 */
+ (instancetype)anotherSharedManager;

/*!
 * @discussion Get the new push manager instance.
 * @return A new push manager instance.
 * NOTE: DO NOT CALL this until you really know!
 */
- (instancetype)init:(BOOL)shared ConnectionMode:(TTPushManagerConnectionMode) mode;
/*!
 * @discussion Setup connection configuration, must be called before the call of start.
 * @param config A TTPushConfig to be used to store the configuration parameters.
 */
- (void)configConnection:(TTPushConfig *)config;
/*!
 * @discussion Try to start the ws connection asynchronously.
 * The conection state will be callbacked by kTTPushManagerConnectionStateChanged notification
 */
- (void)asyncStartConnection;
/*!
 * @discussion Try to stop the ws connection asynchronously.
 * The conection state will be callbacked by kTTPushManagerConnectionStateChanged notification
 */
- (void)asyncStopConnection;
/*!
 * @discussion Try to send a PushMessageBaseObject msg to peer asynchronously.
 * @param message A PushMessageBaseObject.
 * @return bool, true means connection is live.
 */
- (BOOL)asyncSendPushMessage:(/*nonnull*/ PushMessageBaseObject *)message;

/*!
 * @discussion Try to send a binary msg to peer asynchronously.
 * @param message Binary message sent by user.
 * @return bool, true means connection is live.
 */
- (BOOL)asyncSendBinaryMessage:(/*nonnull*/ NSData *)message;

/*!
 * @discussion Try to send a text msg to peer asynchronously.
 * @param message Text message sent by user.
 * @return bool, true means connection is live.
 */
- (BOOL)asyncSendTextMessage:(/*nonnull*/ NSString *)message;

/*!
 * @discussion Try to send a ping of websocket to peer asynchronously.
 */
- (void)asyncSendPing;

/*!
 * @discussion Get the connection state.
 * @return true means the ws connection is connected currently.
 */
- (BOOL)isConnected;

/*!
 * @discussion Application tells sdk about the network change.
 * @param networkState The changed network state.\
 */
- (void)onNetworkStateChanged:(TTPushManagerNetworkState)networkState;

// Nullable parameters, for int kind parameters, must input -1 as if it's optional value
// for string kind parameters, input nil is enough

- (void)startConnection:(/*nonnull*/ NSArray *)urls
                  appId:(/*nonnull*/ int32_t)appId
                   fpid:(/*nonnull*/ int32_t)fpid
                 appKey:(/*nonnull*/ NSString *)appKey
               deviceId:(/*nonnull*/ int64_t)deviceId
             appVersion:(/*nonnull*/ int32_t)appVersion
             sdkVersion:(/*nonnull*/ int32_t)sdkVersion
              installId:(/*nullable*/ int64_t)installId
              sessionId:(/*nullable*/ NSString *)sessionId
                  webId:(/*nullable*/ int64_t)webId
               platform:(/*nullable*/ int32_t)platform
                network:(/*nullable*/ int32_t)network DEPRECATED_ATTRIBUTE;

- (void)startConnection:(/*nonnull*/ NSArray *)urls
                  appId:(/*nonnull*/ int32_t)appId
               deviceId:(/*nonnull*/ int64_t)deviceId
             appVersion:(/*nonnull*/ int32_t)appVersion
             sdkVersion:(/*nonnull*/ int32_t)sdkVersion
              installId:(/*nullable*/ int64_t)installId
              sessionId:(/*nullable*/ NSString *)sessionId
                  webId:(/*nullable*/ int64_t)webId
               platform:(/*nullable*/ int32_t)platform
                network:(/*nullable*/ int32_t)network DEPRECATED_ATTRIBUTE;

- (void)startConnection:(/*nonnull*/ NSArray *)urls
                  appId:(/*nonnull*/ int32_t)appId
                   fpid:(/*nonnull*/ int32_t)fpid
                 appKey:(/*nonnull*/ NSString *)appKey
               deviceId:(/*nonnull*/ int64_t)deviceId
             appVersion:(/*nonnull*/ int32_t)appVersion
             sdkVersion:(/*nonnull*/ int32_t)sdkVersion
              installId:(/*nullable*/ int64_t)installId
              sessionId:(/*nullable*/ NSString *)sessionId
                  webId:(/*nullable*/ int64_t)webId
               platform:(/*nullable*/ int32_t)platform
                network:(/*nullable*/ int32_t)network
           customParams:(nullable NSDictionary<NSString *, NSString *> *)customParams DEPRECATED_ATTRIBUTE;

- (void)stopConnection DEPRECATED_ATTRIBUTE;

/*!
 * @discussion Control the log level.
 * @param enabled true means verbose log enabled.
 */
- (void)enableDebugLog:(BOOL)enabled;

/*!
 * @discussion Set app defined message receiver.
 * @param messageReceiver app defined message receiver.
 */
- (void)setCustomizedMessageReceiver:(TTPushMessageReceiver *)messageReceiver;

/*!
 * @discussion Control the default message received notification(kTTPushManagerOnReceivingMessage).
 * @param value false disable the message receivec notification.
 */
- (void)setBroadcastingMessage:(BOOL)value;

@end

/*!
 * The `WsDelegate` protocol describes the methods that `WsDelegate` objects
 * call on their delegates to handle status and messsage events.
 */
@protocol WsDelegate <NSObject>

@optional
/*!
 * @discussion Called when any message was received from a websocket using wschnannel mode.
 * @param pushManager An instance of `TTPushManager` that received a message.
 * @param message Received message. Either a `NString` or `NSData`.
 * @param type Type is text in a form of UTF-8 `String`, or binary in a form of `NSData`.
 */
- (void)onPushMessageReceived:(TTPushManager*)pushManager message:(id)message type:(TTPushManagerMessageType)type;
/*!
 * @discussion Called when any message was received from a websocket using frontier mode.
 * @param pushManager An instance of `TTPushManager` that received a message.
 * @param message Received message which type is PushMessageBaseObject.
 */
- (void)onFrontierMessageReceived:(TTPushManager*)pushManager message:(PushMessageBaseObject *)message;
/*!
 * @discussion Called when connection established or disconnected from a websocket.
 * @param pushManager An instance of `TTPushManager` that feedback log.
 * @param log The log for establishing or disconnecting connection.
 */
- (void)onFeedbackLog:(TTPushManager*)pushManager feedbacklog:(NSString *)log;
/*!
 * @discussion Called when connection failed with error and state.
 * @param pushManager An instance of `TTPushManager` that failed with error and state.
 * @param state The state of connection when failed.
 * @param url The URL string of websocket connection.
 * @param error The connection error info when failed.
 */
- (void)onConnectionErrorWithState:(TTPushManager*)pushManager connectionState:(TTPushManagerConnectionState)state url:(NSString *)url error:(NSString *)error;
/*!
 * @discussion Called when connection state changed.
 * @param pushManager An instance of `TTPushManager` that stated changed.
 * @param state The state of connection when connected or failed.
 * @param url The URL string of websocket connection.
 */
- (void)onConnectionStateChanged:(TTPushManager*)pushManager connectionState:(TTPushManagerConnectionState)state url:(NSString *)url;


@end
NS_ASSUME_NONNULL_END
