//
//  ACCEditService.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

@protocol IESServiceProvider;

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditService : NSObject <ACCEditServiceProtocol>

- (void)configResolver:(id<IESServiceProvider>)resolver;

@end

NS_ASSUME_NONNULL_END
