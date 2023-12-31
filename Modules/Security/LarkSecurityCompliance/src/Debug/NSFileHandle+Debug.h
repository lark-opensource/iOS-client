//
//  NSFileHandle+Debug.h
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileHandle (Debug)

@property (nonatomic, assign, getter = isSecureAccess) BOOL secureAccess;

@end

NS_ASSUME_NONNULL_END
