//
//  IESEffectContentCollectionViewCell.h
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import <UIKit/UIKit.h>

@class IESEffectModel, IESEffectUIConfig;

typedef void(^EffectPlatformSelectEffectBlock)(NSInteger index);
typedef void(^EffectPlatformDownladEffectBlock)(NSString *effectId, NSError *error, CFTimeInterval duration);

@interface IESEffectContentCollectionViewCell : UICollectionViewCell
- (void)updateWithEffects:(NSArray<IESEffectModel *> *)effects
            selectedIndex:(NSInteger)selectedIndex
                 uiConfig:(IESEffectUIConfig *)uiConfig;
@property (nonatomic, copy) EffectPlatformSelectEffectBlock selectBlock;
@property (nonatomic, copy) EffectPlatformDownladEffectBlock downloadBlock;

@end
