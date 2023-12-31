//
//  ACCPublishMusicTrackModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2019/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPublishMusicTrackModel : NSObject<NSCopying>

@property (nonatomic,   copy) NSString *musicShowRank;
@property (nonatomic,   copy) NSString *selectedMusicID;
@property (nonatomic, strong) NSNumber *musicRecType;

@end

NS_ASSUME_NONNULL_END
