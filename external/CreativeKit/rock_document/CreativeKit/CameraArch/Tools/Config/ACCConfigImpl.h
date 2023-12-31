//
//  ACCConfigImpl.h
//  CreativeKit-Pods-Aweme
//
//  Created by yangying on 2021/3/9.
//

#import <Foundation/Foundation.h>
#import "ACCConfigProtocol.h"
#import <pthread/pthread.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCConfigImpl : NSObject<ACCConfigGetterProtocol, ACCConfigSetterProtocol>

{
    pthread_rwlock_t _rwlock;
}

@property (nonatomic, strong) NSMutableDictionary *configs;

@end

NS_ASSUME_NONNULL_END
