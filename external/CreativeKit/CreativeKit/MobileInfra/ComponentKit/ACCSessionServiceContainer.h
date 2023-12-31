//
//  ACCSessionServiceContainer.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/8/19.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESStaticContainer.h>

@class ACCCreativeSession;

NS_ASSUME_NONNULL_BEGIN

@interface ACCSessionServiceContainer : IESStaticContainer

@property (nonatomic, strong) ACCCreativeSession *session;

@end

NS_ASSUME_NONNULL_END
