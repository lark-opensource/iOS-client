//
//  IESServiceEntry.h
//  IESInject
//
//  Created by bytedance on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import "IESInjectScopeType.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceEntryProtocol <NSObject>

@property (nonatomic, assign, readonly) IESInjectScopeType scopeType;

- (id)extractObject;

@end

@interface IESServiceEntry : NSObject <IESServiceEntryProtocol>

@end

NS_ASSUME_NONNULL_END
