//
//  ACCExternalBussinessTemplate.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/7/19.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESInject.h>
#import "ACCBusinessTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCExternalBussinessTemplate : NSObject<ACCBusinessTemplate>

@property (nonatomic, weak, readonly) AWEVideoPublishViewModel *repository;

- (instancetype)initWithContext:(id<IESServiceProvider>)context;

@end

NS_ASSUME_NONNULL_END
