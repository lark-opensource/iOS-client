//
//  ACCModelFactoryServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/12/28.
//

#ifndef ACCModelFactoryServiceProtocol_h
#define ACCModelFactoryServiceProtocol_h

#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import <CreationKitArch/ACCCutSameTemplateModelProtocol.h>
#import <CreationKitArch/ACCCutSameFragmentModelProtocol.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreationKitArch/ACCTextExtraProtocol.h>
#import <CreationKitArch/ACCUserModelProtocol.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>

@class IESEffectModel;

@protocol ACCModelFactoryServiceProtocol <NSObject>

- (nullable id<ACCChallengeModelProtocol>)createChallengeModelWithItemID:(NSString *)itemId challengeName:(NSString *)challengeName;

- (nullable id<ACCCutSameTemplateModelProtocol>)createCutSameTemplateModelWithEffect:(IESEffectModel *)effectModel isVideoAndPicMixed:(BOOL)isVideoAndPicMixed;

- (nullable id<ACCMVTemplateModelProtocol>)createMVTemplateWithEffectModel:(IESEffectModel *)effectModel urlPrefix:(NSArray<NSString *> *)urlPrefix;

- (nullable id<ACCTextExtraProtocol>)createTextExtra;
- (nullable id<ACCTextExtraProtocol>)createTextExtra:(ACCTextExtraType)type;
- (nullable id<ACCTextExtraProtocol>)createTextExtra:(ACCTextExtraType)type subType:(ACCTextExtraSubType)subType;


- (nullable id<ACCUserModelProtocol>)createUserModel;

- (nullable id<ACCMusicModelProtocol>)createMusicModel;
- (nullable id<ACCMusicModelProtocol>)createMusicModelWithJsonDictionary:(NSDictionary *)jsonDic;

- (nullable id<ACCAwemeModelProtocol>)createAwemeModelWithJsonDictionary:(NSDictionary *)jsonDic;

@end


#endif /* ACCModelFactoryServiceProtocol_h */
