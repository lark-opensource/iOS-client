//
//  ACCRepoNearbyModelProtocol.h
//  CameraClient
//
//  Created by lichangzheng on 2021/7/5.
//

#ifndef ACCRepoNearbyModelProtocol_h
#define ACCRepoNearbyModelProtocol_h

typedef NS_ENUM(NSInteger, ACCCommerceAnchorBusinessType);

@protocol ACCRepoNearbyModelProtocol <NSObject>

@property (nonatomic, assign) BOOL poiFootprintVideo;// 是否是足迹视频

/// 足迹视频锚点id
- (NSString *)acc_footprintAnchorID;
/// 足迹视频锚点type
- (ACCCommerceAnchorBusinessType)acc_footprintAnchorBusinessType;

@end

#endif /* ACCRepoNearbyModelProtocol_h */
