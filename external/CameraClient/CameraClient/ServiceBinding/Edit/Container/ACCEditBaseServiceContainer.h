//
//  ACCEditBaseServiceContainer.h
//  Pods
//
//  Created by Liu Deping on 2020/6/13.
//

#import <IESInject/IESInject.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBusinessInputData;
@protocol ACCUIViewControllerProtocol;

@interface ACCEditBaseServiceContainer : IESStaticContainer

@property (nonatomic, weak, readonly) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readonly) id<ACCUIViewControllerProtocol> viewController;

@end

NS_ASSUME_NONNULL_END
