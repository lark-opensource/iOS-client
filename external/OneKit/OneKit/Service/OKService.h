//
//  OKService.h
//  OneKit
//
//  Created by bob on 2020/5/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OKService <NSObject>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
