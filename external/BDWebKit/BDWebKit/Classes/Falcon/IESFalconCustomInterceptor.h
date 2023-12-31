//
//  IESFalconCustomInterceptor.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/19.
//

#import "IESFalconStatModel.h"

NS_ASSUME_NONNULL_BEGIN

#ifndef IESFalconCustomInterceptor_h
#define IESFalconCustomInterceptor_h

@protocol IESFalconMetaData <NSObject>

@property (nonatomic, strong) NSData * _Nullable falconData;

@property (nonatomic, strong) IESFalconStatModel *statModel;

@optional

@property (nonatomic, readonly) NSDictionary *allHeaderFields;
@property (nonatomic, readonly) NSInteger    statusCode;

@end

@protocol IESFalconCustomInterceptor <NSObject>

@optional
- (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request;

- (NSData * _Nullable)falconDataForURLRequest:(NSURLRequest *)request;

- (NSUInteger)falconPriority;

- (BOOL)shouldInterceptForRequest:(NSURLRequest*)request;

@end

#endif /* IESFalconCustomInterceptor_h */

NS_ASSUME_NONNULL_END
