//
//  ACCFlowerPropPanelService.h
//  CameraClient-Pods-AwemeCore
//
//  Created by qiyang on 2021/11/23.
//

#import <Foundation/Foundation.h>

@class IESEffectModel;

@protocol ACCFlowerPropPanelService <NSObject>

@property (nonatomic, assign, readonly) BOOL isShootPropPanelShow;

- (void)flowerTrackForEnterFlowerCameraTab:(NSString *)enterMethod propID:(NSString *)propID;

@end
