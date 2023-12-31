//
//  BDIRPCStatus.h
//  BDiOSpy
//
//  Created by byte dance on 2021/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDIRPCStatus : NSObject

@property (nonatomic, copy, readonly) NSString *error;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, assign) NSInteger errorCode;

+ (instancetype)serverErrorWithMessage:(NSString *)message;
+ (instancetype)internalErrorWithMessage:(NSString *)message;
+ (instancetype)invalidParamsErrorWithMessage:(NSString *)message;
+ (instancetype)methodNotFoundErrorWithMessage:(NSString *)message;
+ (instancetype)invalidRequestErrorWithMessage:(NSString *)message;
+ (instancetype)parseErrorWithMessage:(NSString *)message;
+ (instancetype)errorWithMessage:(NSString *)message errorCode:(NSInteger)errorCode;
@end

NS_ASSUME_NONNULL_END
