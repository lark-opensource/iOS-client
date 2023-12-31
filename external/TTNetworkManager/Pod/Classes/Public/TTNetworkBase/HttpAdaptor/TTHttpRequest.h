//
//  TTHttpRequest.h
//  Pods
//
//  Created by gaohaidong on 9/23/16.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

#pragma mark - new auth credentials object
/**
 * Authentication Credentials for an http authentication credentials.
 */
@interface TTAuthCredentials : NSObject
// The username to provide, possibly empty.
@property(nonatomic, copy) NSString *username;
// The password to provide, possibly empty.
@property(nonatomic, copy) NSString *password;

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;
@end

@interface TTHttpRequest : NSObject

/*!
 @property HTTPMethod
 @abstract Returns the HTTP request method of the receiver.
 @result the HTTP request method of the receiver.
 */
@property (nullable, copy) NSString *HTTPMethod;

/*!
 @property URL
 @abstract Sets the URL of the receiver.
 @result URL The new URL for the receiver.
 */
@property (nullable, copy) NSURL *URL;

/*!
 @property setTimeoutInterval:
 @result seconds The new timeout interval of the receiver.
 */
@property (assign) NSTimeInterval timeoutInterval;

/*!
 @property HTTPBody
 @abstract Returns the request body data of the receiver.
 @discussion This data is sent as the message body of the request, as
 in done in an HTTP POST request.
 @result The request body data of the receiver.
 */
@property (nullable, copy) NSData *HTTPBody;

/*!
 @property uploadFilePath
 @abstract Returns the upload file path.
 @discussion This path target file is sent as the message body of the request, as
 in done in an HTTP POST request.
 @result The upload file path.
 */
@property (nullable, copy) NSString *uploadFilePath;

/*!
 @property allHTTPHeaderFields
 @abstract Returns a dictionary containing all the HTTP header fields
 of the receiver.
 @result a dictionary containing all the HTTP header fields of the
 receiver.
 */
@property (nullable, copy) NSDictionary<NSString *, NSString *> *allHTTPHeaderFields;

/*!
 @property followRedirect
 @abstract set boolean value means if follow 3xx http redirection.
 @result true follow redirection.
 */
@property (assign) BOOL followRedirect;

@property (nullable, readonly, strong) NSMutableDictionary<NSString *, NSNumber *> *filterObjectsTimeInfo;

@property (readonly, strong) NSMutableDictionary<NSString *, NSNumber *> *serializerTimeInfo;

@property (nullable, readonly, copy) NSDictionary *webviewInfo;

//To make sure that concurrent request only sends one finish notification
@property (nonatomic, assign) BOOL shouldReportLog;

@property (atomic, readonly, assign) BOOL isSerializedOnMainThread;

/**
 *Set whether to bypass proxy.
 *YES: Can't use proxy for each request.
 *NO: Can use proxy for each request
 */
@property(nonatomic, assign) BOOL bypassProxy;

/**
 *The proxy authentication credentials.
 */
@property(nonatomic, strong) TTAuthCredentials *authCredentials;

/** the time when users call TTNetworkManager's api
 **  used for calculate biz_total_time
 */
@property(nonatomic, strong) NSDate *startBizTime;

/*!
 @method valueForHTTPHeaderField:
 @abstract Returns the value which corresponds to the given header
 field. Note that, in keeping with the HTTP RFC, HTTP header field
 names are case-insensitive.
 @param field the header field name to use for the lookup
 (case-insensitive).
 @result the value associated with the given header field, or nil if
 there is no value associated with the given header field.
 */
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;

/*!
 @method setValue:forHTTPHeaderField:
 @abstract Sets the value of the given HTTP header field.
 @discussion If a value was previously set for the given header
 field, that value is replaced with the given value. Note that, in
 keeping with the HTTP RFC, HTTP header field names are
 case-insensitive.
 @param value the header field value.
 @param field the header field name (case-insensitive).
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

/*!
 @method addValue:forHTTPHeaderField:
 @abstract Adds an HTTP header field in the current header
 dictionary.
 @discussion This method provides a way to add values to header
 fields incrementally. If a value was previously set for the given
 header field, the given value is appended to the previously-existing
 value. The appropriate field delimiter, a comma in the case of HTTP,
 is added by the implementation, and should not be added to the given
 value by the caller. Note that, in keeping with the HTTP RFC, HTTP
 header field names are case-insensitive.
 @param value the header field value.
 @param field the header field name (case-insensitive).
 */
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end
NS_ASSUME_NONNULL_END
