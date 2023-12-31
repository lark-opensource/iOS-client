//
//  IESCategoryModel+AWEAdditions.h
//  AWEStudio
//
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <EffectPlatformSDK/IESCategoryModel.h>

@interface IESCategoryModel (AWEAdditions)

@property (nonatomic, strong) NSArray<IESEffectModel *> *aweStickers;

- (BOOL)shouldUseIconDisplay;

@end
