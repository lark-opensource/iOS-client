//
//  TSPKUtils.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/16.
//

#import <Foundation/Foundation.h>

extern NSString *_Nonnull const TSPKReturnTypeNSString;
extern NSString *_Nonnull const TSPKReturnTypeNSArray;
extern NSString *_Nonnull const TSPKReturnTypeNSNumber;
extern NSString *_Nonnull const TSPKReturnTypeNSURL;
extern NSString *_Nonnull const TSPKReturnTypeNSUUID;

@interface TSPKUtils : NSObject

+ (NSString *_Nonnull)appendUnitName:(NSString *_Nonnull)unitName toRouter:(NSString *_Nonnull)router;

+ (NSString *_Nonnull)decodeBase64String:(NSString *_Nonnull)encodeString;

+ (NSString *_Nullable)topVCName;

+ (NSString *_Nonnull)version;

+ (NSString *_Nonnull)settingVersion;

+ (NSString *_Nullable)appStatusString;
+ (NSString *_Nullable)appStatusWithDefault:(NSString *_Nullable)defaultVal;

+ (NSTimeInterval)getRelativeTime;
+ (NSTimeInterval)getRelativeTimeWithMillisecond;

+ (NSTimeInterval)getUnixTime;
+ (NSTimeInterval)getServerTime;

+ (NSString *_Nullable)concateClassName:(NSString *_Nullable)className method:(NSString *_Nullable)method;
+ (NSString *_Nullable)concateClassName:(NSString *_Nullable)className method:(NSString *_Nullable)method joiner:(NSString *_Nullable)joiner;

+ (void)exectuteOnMainThread:(void (^_Nonnull)(void))block;

//avoid memory leak with block in debug build
+ (void)assert:(BOOL)flag message:(NSString *_Nonnull)message;

+ (void)logWithMessage:(id __nonnull)logObj;
+ (void)logWithTag:(NSString *__nonnull)tag message:(id __nonnull)logObj;

+ (nullable NSString *)generateUUID;

+ (NSInteger)appID;

+ (nullable NSString *)jsonStringEncodeWithObj:(nullable id)obj;

+ (id _Nullable )createDefaultInstance:(NSString *_Nullable)encodeType defalutValue:(NSString*_Nullable)defaultVal;
+ (long long)createDefaultValue:(NSString *_Nullable)encodeType defalutValue:(NSString* _Nullable)defaultVal;

// when totally use rule engine, remove it
+ (nonnull NSError*)fuseError;

+ (nullable id)parseJsonStruct:(nullable id)json;

+ (NSInteger)convertDoubleToNSInteger:(double)doubleValue;

@end


