//
//  MODModelFactoryServiceImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/2.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import "MODModelFactoryServiceImpl.h"

@implementation MODModelFactoryServiceImpl

- (nullable id<ACCAwemeModelProtocol>)createAwemeModelWithJsonDictionary:(NSDictionary *)jsonDic {
    return nil;
}

- (nullable id<ACCChallengeModelProtocol>)createChallengeModelWithItemID:(NSString *)itemId challengeName:(NSString *)challengeName {
    return nil;
}

- (nullable id<ACCCutSameTemplateModelProtocol>)createCutSameTemplateModelWithEffect:(IESEffectModel *)effectModel isVideoAndPicMixed:(BOOL)isVideoAndPicMixed {
    return nil;
}

- (nullable id<ACCMVTemplateModelProtocol>)createMVTemplateWithEffectModel:(IESEffectModel *)effectModel urlPrefix:(NSArray<NSString *> *)urlPrefix {
    return nil;
}

- (nullable id<ACCMusicModelProtocol>)createMusicModel {
    return nil;
}

- (nullable id<ACCMusicModelProtocol>)createMusicModelWithJsonDictionary:(NSDictionary *)jsonDic {
    return nil;
}

- (nullable id<ACCTextExtraProtocol>)createTextExtra {
    return nil;
}

- (nullable id<ACCUserModelProtocol>)createUserModel {
    return nil;
}

- (nullable id<ACCTextExtraProtocol>)createTextExtra:(ACCTextExtraType)type {
    return nil;
}


- (nullable id<ACCTextExtraProtocol>)createTextExtra:(ACCTextExtraType)type subType:(ACCTextExtraSubType)subType {
    return nil;
}


@end
