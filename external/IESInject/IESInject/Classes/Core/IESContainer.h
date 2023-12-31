//
//  IESContainer.h
//  IESInject
//
//  Created by bytedance on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import "IESServiceContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESContainer : NSObject <IESServiceRegister, IESServiceProvider>

- (instancetype)initWithParentContainer:(nullable IESContainer *)container;

@end

NS_ASSUME_NONNULL_END
