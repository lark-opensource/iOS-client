//
//  IESFalconInfo.h
//  Pods
//
//  Created by 陈煜钏 on 2019/10/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString  * _Nullable (^BDWKGetDeviceIDBlock)(void);

@interface IESFalconInfo : NSObject

@property (class, nonatomic, copy) NSString *deviceId;
@property (class, nonatomic, copy) NSString *platformDomain;

+ (void)setGetDeviceIDBlock:(BDWKGetDeviceIDBlock)getDeviceIDBlock;

@end

NS_ASSUME_NONNULL_END
