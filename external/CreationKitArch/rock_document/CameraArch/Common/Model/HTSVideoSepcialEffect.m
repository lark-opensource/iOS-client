//
//  HTSVideoSepcialEffect.m
//  Aweme
//
//  Created by Liu Bing on 11/25/16.
//  Copyright © 2016 Bytedance. All rights reserved.
//

#import "HTSVideoSepcialEffect.h"
#import <CreativeKit/ACCLanguageProtocol.h>

@implementation HTSVideoSepcialEffect

+ (UIColor *)effectColorWithType:(HTSPlayerTimeMachineType)type
{
    switch (type) {
        case HTSPlayerTimeMachineNormal:
            return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        case HTSPlayerTimeMachineReverse:
            return [UIColor colorWithRed:253 / 255.0 green:81 / 255.0 blue:217 / 255.0 alpha:0.9];
        case HTSPlayerTimeMachineTimeTrap:
            return [UIColor colorWithRed:104 / 255.0 green:89 / 255.0 blue:234 / 255.0 alpha:0.9];
        case HTSPlayerTimeMachineRelativity:
            return [UIColor colorWithRed:126 / 255.0 green:211 / 255.0 blue:33 / 255.0 alpha:0.9];
    }
}

+ (NSArray *)allEffects
{
    static NSMutableArray *effects = nil;
    if (!effects) {
        NSArray *effectNames = @[ ACCLocalizedString(@"none", @"none"), ACCLocalizedString(@"time_effect1", nil), ACCLocalizedString(@"com_mig_repeat", nil), ACCLocalizedString(@"time_effect3", nil)];
        NSArray *effectAnimatedImageNames = @[@"normal.webp", @"shiguangdaoliu2.webp", @"repeat.webp", @"mandongzuo2.webp"];
        NSArray *effectTypes = @[@(HTSPlayerTimeMachineNormal), @(HTSPlayerTimeMachineReverse), @(HTSPlayerTimeMachineTimeTrap), @(HTSPlayerTimeMachineRelativity)];
        NSUInteger count = effectNames.count;
        effects = [NSMutableArray arrayWithCapacity:count];
        for (NSInteger i = 0; i < count; i++) {
            HTSVideoSepcialEffect *effect = [[HTSVideoSepcialEffect alloc] init];
            effect.timeEffectId = @(i);
            effect.name = effectNames[i];
            effect.timeMachineType = [effectTypes[i] integerValue];
            effect.animatedImageName = effectAnimatedImageNames[i];
            effect.effectColor = [self effectColorWithType:effect.timeMachineType];
            [effects addObject:effect];
        }
    }

    return effects;
}

+ (void)resetForbid {
    for (HTSVideoSepcialEffect *effect in [self allEffects]) {
        effect.forbidden = NO;
    }
}

+ (NSString *)descriptionWithType:(HTSPlayerTimeMachineType)type
{
    return ACCLocalizedString(@"effect_time_click", @"Tap to use time warp effects");
}

+ (instancetype)effectWithType:(HTSPlayerTimeMachineType)type
{
    NSArray *effectArray = [self allEffects];
    for (HTSVideoSepcialEffect *effect in effectArray) {
        if (effect.timeMachineType == type) {
            return effect;
        }
    }
    return nil;
}

- (UIColor *)effectColorWithType:(HTSPlayerTimeMachineType)type
{
    return [[self class] effectColorWithType:type];
}

- (NSArray *)allEffects
{
    return [[self class] allEffects];
}

- (void)resetForbid {
    return [[self class] resetForbid];
}

- (NSString *)descriptionWithType:(HTSPlayerTimeMachineType)type
{
    return [[self class] descriptionWithType:type];
}

- (instancetype)effectWithType:(HTSPlayerTimeMachineType)type
{
    return [[self class] effectWithType:type];
}

@end
