//
//  ACCIMServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPublishRepository;

@protocol ACCIMServiceProtocol <NSObject>

- (NSString * _Nonnull)couldShowPolymericMessagesNotification;

// flybird
- (BOOL)isEnterFromFlyBird:(id<ACCPublishRepository>)repository;

@end

NS_ASSUME_NONNULL_END
