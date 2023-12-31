//
//  ACCViewModelFactory.h
//  CameraClient
//
//  Created by Liu Deping on 2020/7/12.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESInject.h>
#import "ACCBusinessConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCViewModelFactory <NSObject>

- (id)createViewModel:(Class)modelClass;

@end

@protocol ACCBusinessInputData;

@interface ACCViewModelFactory : NSObject <ACCViewModelFactory>

- (instancetype)initWithContext:(id<IESServiceProvider>)context;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
