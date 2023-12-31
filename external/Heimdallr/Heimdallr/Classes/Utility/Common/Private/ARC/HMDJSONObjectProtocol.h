//
//  HMDJSONObjectProtocol.h
//  Pods
//
//  Created by Nickyo on 2023/4/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDJSONObjectProtocol <NSObject>

- (BOOL)hmd_isValidJSONObject;

- (NSData * _Nullable)hmd_jsonDataWithOptions:(NSJSONWritingOptions)opt error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
