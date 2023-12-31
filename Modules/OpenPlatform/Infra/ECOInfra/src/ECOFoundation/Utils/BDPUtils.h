//
//  BDPUtils.h
//  ECOInfra
//
//  Created by Meng on 2021/3/25.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Check if we are currently on the main queue (not to be confused with
/// the main thread, which is not necessarily the same thing)
FOUNDATION_EXTERN BOOL BDPIsMainQueue(void);

/// Returns YES if React is running in an iOS App Extension
FOUNDATION_EXTERN BOOL BDPRunningInAppExtension(void);

/// Returns the shared UIApplication instance, or nil if running in an App Extension
FOUNDATION_EXTERN UIApplication * _Nullable BDPSharedApplication(void);

/// Create an NSError in the BDPErrorDomain
FOUNDATION_EXTERN NSError * _Nullable BDPErrorWithMessage(NSString * _Nullable message);

/// create an NSError in the BDPErrorDomain by message and error code
FOUNDATION_EXTERN NSError * _Nullable BDPErrorWithMessageAndCode(NSString * _Nullable message, NSInteger code);

/// create an NSError in the BDPErrorDomain by message and error code and error domain (domain cannot be nil)
FOUNDATION_EXTERN NSError * _Nullable BDPErrorWithMessageAndCodeAndDomain(NSString * _Nullable message, NSInteger code, NSString * _Nonnull domain);

/// Returns the error from network.
FOUNDATION_EXTERN NSError * _Nullable BDPErrorWithResponse(id _Nullable responseData, NSError * _Nullable error);

/// Save Image To Album
FOUNDATION_EXTERN void BDPSaveImageToPhotosAlbum(NSString * _Nullable tokenIdentifier, NSData * _Nullable imageData, void(^ _Nullable completion)(BOOL success, NSError *_Nullable error));

/// Save Video To Album
FOUNDATION_EXTERN void BDPSaveVideoToPhotosAlbum(NSString * _Nullable tokenIdentifier, NSURL * _Nullable fileURL, void(^ _Nullable completion)(BOOL success, NSError *_Nullable error));

/// Returns a string of the specified length
FOUNDATION_EXTERN NSString * _Nonnull BDPRandomString(NSInteger length);

/// Returns MIME Type of a path (default: @"text/plain")
FOUNDATION_EXTERN NSString * _Nonnull BDPMIMETypeOfFilePath(NSString * _Nullable filePath);

/// Returns the app id of host.
/// e.g. Toutiao is 13, Aweme is 1282
FOUNDATION_EXTERN NSInteger BDPHostAppId(void);

/// Returns current system version
/// e.g. 12.0.0
FOUNDATION_EXTERN NSString * _Nonnull BDPSystemVersion(void);

/// Returns If Array is Empty or Invalid
FOUNDATION_EXTERN BOOL BDPIsEmptyArray(NSArray * _Nullable array);

/// Returns If String is Empty or Invalid
FOUNDATION_EXTERN BOOL BDPIsEmptyString(NSString * _Nullable string);

/// Returns If Dictionary is Empty or Invalid
FOUNDATION_EXTERN BOOL BDPIsEmptyDictionary(NSDictionary * _Nullable dict);

/// Returns NSArray Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSArray * _Nonnull BDPSafeArray(NSArray * _Nullable array);

/// Returns NSString Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSString * _Nonnull BDPSafeString(NSString * _Nullable string);

/// Returns NSDictionary Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSDictionary * _Nonnull BDPSafeDictionary(NSDictionary * _Nullable dict);

NS_ASSUME_NONNULL_END
