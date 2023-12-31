//
//  ACCRecorderServiceContainer.h
//  Pods
//
//  Created by Liu Deping on 2020/6/8.
//

#import <IESInject/IESInject.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBusinessInputData;
@protocol ACCViewController;

@interface ACCRecorderServiceContainer : IESStaticContainer

@property (nonatomic, weak, readonly) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readonly) id<ACCViewController> viewController;

@end

NS_ASSUME_NONNULL_END
