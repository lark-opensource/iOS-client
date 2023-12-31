//
// JATFakeObject.h
// 
//
// Created by Aircode on 2022/8/12

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JATFakeObjectAssert : NSProxy

@property (nonatomic, strong, readonly) id target;
@property (nonatomic, assign, readonly) BOOL exceptionUpload;

+ (instancetype)useFakeObjAssertWithTarget:(id)target uploadException:(BOOL)uploadException;

@end

NS_ASSUME_NONNULL_END
