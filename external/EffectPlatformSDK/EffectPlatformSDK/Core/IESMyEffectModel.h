//
//  IESMyEffectModel.h
//  EffectPlatformSDK
//
//  Created by leizh007 on 2018/4/13.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "IESEffectModel.h"

@interface IESMyEffectModel : MTLModel

@property(nonatomic, copy) NSString *type;

@property(nonatomic, copy) NSArray<IESEffectModel *> *effects;

@property(nonatomic, copy) NSArray<IESEffectModel *> *bindEffects;

- (void)updateEffects;

@end
