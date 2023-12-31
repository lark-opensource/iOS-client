//
//  ACCRepoLastGroupTrackModelProtocol.h
//  CameraClient
//
//  Created by Syenny on 2021/4/28.
//

#ifndef ACCRepoLastGroupTrackModelProtocol_h
#define ACCRepoLastGroupTrackModelProtocol_h

@protocol ACCRepoLastGroupTrackModelProtocol <NSObject>

/**
 from_group_id : 开拍前最后一个看到的视频 局部 推荐/关注/同城
 last_group_id : 开拍前最后一个看到的全屏视频 全局
 last_gid_from : last_group_id 所属的页面
 originalGroupID : 源头的 last_group_id
 originalGidDistance : 本次投稿与源头 last_group_id 路径的长度
 */
@property (nonatomic, copy) NSString *fromGroupID;
@property (nonatomic, copy) NSString *lastGroupID;
@property (nonatomic, copy) NSString *lastGIDFrom;
@property (nonatomic, copy) NSString *originalGroupID;
@property (nonatomic, assign) NSInteger originalGidDistance;

- (NSDictionary *)originalGroupInfo;

@end

#endif /* ACCRepoLastGroupTrackModelProtocol_h */
