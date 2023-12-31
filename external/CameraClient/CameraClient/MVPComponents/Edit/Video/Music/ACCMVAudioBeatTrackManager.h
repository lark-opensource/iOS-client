//
//  ACCMVAudioBeatTrackManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/10/27.
//

#import <Foundation/Foundation.h>

@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCMVAudioBeatTrackManager : NSObject

// 以下字段都是Loki后台配置下发，参照extra.json
@property (nonatomic, assign) float srcIn;
@property (nonatomic, assign) float srcOut;
@property (nonatomic, assign) float dstIn;
@property (nonatomic, assign) float dstOut;
@property (nonatomic, assign) BOOL isAudioBeatTrack;
@property (nonatomic, copy, nullable) NSString *musicFileName;
@property (nonatomic, strong, readonly) IESEffectModel *effectModel;

- (instancetype)initWithMVEffectModel:(IESEffectModel *)effectModel;

// 获取模板算法本地相对路径
- (NSString * _Nullable)modelRelativePathForAlgorithm;

@end

NS_ASSUME_NONNULL_END
