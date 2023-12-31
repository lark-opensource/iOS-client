//
//  ACCEditorComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/18.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESServiceProvider.h>

@class AWEVideoPublishViewModel;

@interface ACCEditorComponent : NSObject

@property (nonatomic, strong, nullable, readonly) id<IESServiceProvider, IESServiceRegister> serviceProvider;
@property (nonatomic, strong, nullable) AWEVideoPublishViewModel *repository;
- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider, IESServiceRegister>) serviveProvider;

- (void)setupWithCompletion:(nullable void (^)(NSError * _Nullable))completion;

@end
