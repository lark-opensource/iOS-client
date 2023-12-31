//
//  HTSVideoSepcialEffect.h
//  Aweme
//
//  Created by Liu Bing on 11/25/16.
//  Copyright © 2016 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTVideoEditor/HTSVideoData.h>

@interface HTSVideoSepcialEffect : NSObject

@property (nonatomic, strong) NSNumber *timeEffectId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *animatedImageName;
@property (nonatomic) HTSPlayerTimeMachineType timeMachineType;
@property (nonatomic, assign) CGFloat beginTime;

@property (nonatomic, strong) UIColor *effectColor;
@property (nonatomic, assign) BOOL forbidden;

+ (NSArray *)allEffects;
+ (instancetype)effectWithType:(HTSPlayerTimeMachineType)type;
+ (UIColor *)effectColorWithType:(HTSPlayerTimeMachineType)type;
+ (NSString *)descriptionWithType:(HTSPlayerTimeMachineType)type;
+ (void)resetForbid;

- (NSArray *)allEffects;
- (instancetype)effectWithType:(HTSPlayerTimeMachineType)type;
- (UIColor *)effectColorWithType:(HTSPlayerTimeMachineType)type;
- (NSString *)descriptionWithType:(HTSPlayerTimeMachineType)type;
- (void)resetForbid;

@end
