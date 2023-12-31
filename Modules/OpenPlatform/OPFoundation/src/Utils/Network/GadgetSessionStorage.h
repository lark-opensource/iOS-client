//
//  GadgetSessionStorage.h
//  TTMicroApp
//
//  Created by Meng on 2021/4/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GadgetSessionStorage <NSObject>

@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *sessionHeader;

@end

NS_ASSUME_NONNULL_END
