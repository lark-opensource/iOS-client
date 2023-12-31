//
//  AWEStickerMusicManager+Local.h
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/19.
//

#import <CreationKitArch/AWEStickerMusicManager.h>
@protocol ACCMusicModelProtocol;
@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerMusicManager (Local)

+ (BOOL)insertMusicModelToCache:(id<ACCMusicModelProtocol>)musicModel;
 
+ (id<ACCMusicModelProtocol> _Nullable)fetchtMusicModelFromCache:(NSString *)musicID;

+ (NSURL * _Nullable)localURLForMusic:(id<ACCMusicModelProtocol>)musicModel;

+ (BOOL)needToDownloadMusicWithEffectModel:(IESEffectModel *)effectModel;

@end

NS_ASSUME_NONNULL_END
