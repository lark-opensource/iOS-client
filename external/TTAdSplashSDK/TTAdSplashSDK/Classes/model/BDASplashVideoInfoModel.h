//
//  BDASplashVideoInfoModel.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频数据 model 类
@interface BDASplashVideoInfoModel : NSObject
@property (nonatomic, copy, readonly) NSString *videoId;
@property (nonatomic, copy, readonly) NSString *videoGroupId;
@property (nonatomic, copy, readonly) NSArray *videoURLArray;
@property (nonatomic, copy, readonly) NSArray *videoPlayTrackURLArray;
@property (nonatomic, copy, readonly) NSArray *videoPlayOverTrackURLArray;
@property (nonatomic, copy, readonly) NSString *videoDensity;
@property (nonatomic, copy, readonly) NSString *videoSecretKey;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
NS_ASSUME_NONNULL_END
