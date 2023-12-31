//
//  ACCMomentAlgorithmRecord.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/17.
//

#import <Mantle/MTLModel.h>
#import <EffectPlatformSDK/IESAlgorithmRecord.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentAlgorithmRecord : MTLModel

@property (nonatomic, copy) NSString *name; // Primary property

@property (nonatomic, copy) NSString *version;

@property (nonatomic, copy) NSString *modelMD5;

- (instancetype)initWithOriginModel:(IESAlgorithmRecord *)originModel;

@end

NS_ASSUME_NONNULL_END
