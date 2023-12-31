//
//  IESServiceProvider.h
//  IESInject
//
//  Created by bytedance on 2020/2/10.
//

#import <Foundation/Foundation.h>
#import "IESContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESServiceProvider : NSObject <IESServiceProvider>

- (instancetype)initWithContainer:(IESContainer *)container;

@end

NS_ASSUME_NONNULL_END
