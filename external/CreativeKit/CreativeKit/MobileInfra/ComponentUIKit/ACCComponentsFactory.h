//
//  ACCComponentsFactory.h
//  CameraClient
//
//  Created by Liu Deping on 2020/7/12.
//

#import <Foundation/Foundation.h>
#import "ACCComponentController.h"
#import "ACCViewModelFactory.h"
#import "ACCBusinessTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceRegister, IESServiceProvider;

@interface ACCComponentsFactory : NSObject

- (instancetype)initWithContext:(id<IESServiceProvider>)context;

- (void)loadComponents;

@end

NS_ASSUME_NONNULL_END
