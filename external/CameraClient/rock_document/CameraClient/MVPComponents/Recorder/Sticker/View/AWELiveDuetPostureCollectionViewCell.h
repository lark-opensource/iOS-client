//
//  AWELiveDuetPostureCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/1/14.
//

#import "AWEStudioBaseCollectionViewCell.h"
#import <CreationKitInfra/AWECircularProgressView.h>

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWELiveDuetPostureCollectionViewCell : AWEStudioBaseCollectionViewCell

@property (nonatomic, assign, readonly) BOOL isCellSelected;

- (void)updateSelectedStatus:(BOOL)selected;

- (void)updateIconImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
