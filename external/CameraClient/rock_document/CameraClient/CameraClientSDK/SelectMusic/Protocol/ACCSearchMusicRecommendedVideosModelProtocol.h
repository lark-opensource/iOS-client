//
//  ACCSearchMusicRecommendedVideosModelProtocol.h
//  CameraClient
//
//  Created by Chen Long on 2020/11/19.
//

#import <CreationKitArch/ACCAwemeModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSearchMusicRecommendedVideosModelProtocol <NSObject>

@property (nonatomic, copy) NSString *aladdinSource;
@property (nonatomic, copy) NSString *docID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSArray <id<ACCAwemeModelProtocol>> *videoList;

@end

NS_ASSUME_NONNULL_END

