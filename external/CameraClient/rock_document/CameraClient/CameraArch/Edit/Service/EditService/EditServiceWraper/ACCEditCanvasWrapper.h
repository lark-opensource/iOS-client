//
//  ACCEditCanvasWrapper.h
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditCanvasWrapper : NSObject <ACCEditCanvasProtocol>

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
