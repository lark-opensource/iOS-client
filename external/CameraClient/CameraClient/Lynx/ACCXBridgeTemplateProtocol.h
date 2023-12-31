//
//  ACCXBridgeTemplateProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/8.
//

#import <Foundation/Foundation.h>

@protocol IESServiceProvider;
@class BDXBridgeMethod;

@protocol ACCXBridgeTemplateProtocol<NSObject>

- (NSArray<BDXBridgeMethod *> *)xBridgeRecorderTemplate:(nonnull id<IESServiceProvider>)serviceProvider;

@end

