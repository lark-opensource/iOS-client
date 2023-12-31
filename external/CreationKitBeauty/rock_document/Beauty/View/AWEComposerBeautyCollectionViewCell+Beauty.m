//
//  AWEComposerBeautyCollectionViewCell+Beauty.m
//  CameraClient
//
//  Created by zhangyuanming on 2020/8/26.
//

#import <CreationKitBeauty/AWEComposerBeautyCollectionViewCell+Beauty.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@implementation AWEComposerBeautyCollectionViewCell (Beauty)

- (void)configWithBeauty:(nonnull AWEComposerBeautyEffectWrapper *)effectWrapper {
    
    self.isNewStyle = YES;
    self.iconStyle = self.iconStyle;
    self.isSmallIcon = NO;
    [self setTitle:effectWrapper.effect.effectName];
    [self setImageWithUrls:effectWrapper.effect.iconDownloadURLs placeholder:ACCResourceImage(@"ic_loading_rect")];
    if (effectWrapper.effect.builtinIcon) {
        self.isSmallIcon = YES;
        [self setIconImage:ACCResourceImage(effectWrapper.effect.builtinIcon)];
    }

    [self setFlagDotViewHidden:!effectWrapper.isNew];
    [self setAvailable:effectWrapper.available];
}

@end
