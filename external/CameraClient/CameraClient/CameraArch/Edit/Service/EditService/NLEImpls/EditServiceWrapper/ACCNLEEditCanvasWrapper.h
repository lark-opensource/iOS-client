//
//  ACCNLEEditCanvasWrapper.h
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/4/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCNLEEditCanvasWrapper : NSObject<ACCEditCanvasProtocol>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
