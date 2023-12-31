//
//  IESEffectModel+ACCRedpacket.h
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/11/10.
//

#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModel (ACCRedpacket)

@property (nonatomic, readonly) BOOL acc_isTC21Redpacket;
@property (nonatomic, readonly) BOOL acc_supportLiteRedpacket;
@property (nonatomic, readonly) BOOL acc_isLiteRedpacket;
@property (nonatomic, nullable, readonly) NSString *acc_redpacketKey;
@property (nonatomic, nullable, readonly) NSString *acc_composerPath;
@property (nonatomic, nullable, readonly) NSString *videoGroupID;

- (BOOL)enableEffectMusicTime;
- (BOOL)allowMusicBeatCancelMusic;

@end

NS_ASSUME_NONNULL_END
