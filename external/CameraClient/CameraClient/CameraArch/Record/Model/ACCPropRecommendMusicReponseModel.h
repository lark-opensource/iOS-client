//
//  ACCPropRecommendMusicReponseModel.h
//  CameraClient
//
//  Created by xiaojuan on 2020/8/10.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropRecommendMusicReponseModel : NSObject

@property (nonatomic, copy, nullable) NSArray<id<ACCMusicModelProtocol>> *recommendMusicList;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> weakBindMusic;
@property (nonatomic, copy, nullable) NSString *bubbleTitle;

/// 获取道具推荐音乐列表和弱绑定音乐
+ (void)fetchStickerRecommendMusicList:(IESEffectModel *)sticker
                              createId:(NSString *)createId
                     completionHandler:(void (^)(ACCPropRecommendMusicReponseModel * _Nullable responseModel, NSError * _Nullable error))completionHandler;

+ (BOOL)shouldForbidRequestRecommendMusicInfoWithEffectModel:(IESEffectModel *)effect;

@end

NS_ASSUME_NONNULL_END
