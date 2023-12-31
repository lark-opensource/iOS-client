//
//  IESGurdRegisterModel.h
//  BDAssert
//
//  Created by 陈煜钏 on 2021/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdRegisterModel : NSObject

@property (nonatomic, readonly, copy) NSString *accessKey;

@property (nonatomic, readonly, copy) NSString *version;

@property (nonatomic, copy) NSDictionary *customParams;

@property (nonatomic, assign) BOOL isRegister;

@end

NS_ASSUME_NONNULL_END
