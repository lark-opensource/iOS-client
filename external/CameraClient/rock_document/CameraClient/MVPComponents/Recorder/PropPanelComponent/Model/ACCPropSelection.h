//
//  ACCPropSelection.h
//  CameraClient
//
//  Created by Shen Chen on 2020/5/14.
//

#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitRTProtocol/AWEComposerEffectProtocol.h>
#import <Photos/Photos.h>

@interface ACCPropSelection : NSObject
@property (nonatomic, strong) IESEffectModel *effect;
@property (nonatomic, strong) IESEffectModel *childEffect;
@property (nonatomic, strong) id<AWEComposerEffectProtocol> composerEffect;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) ACCPropSelectionSource source;
- (instancetype)initWithEffect:(IESEffectModel *)effect childEffect:(IESEffectModel *)childEffect source:(ACCPropSelectionSource)source;
- (instancetype)initWithEffect:(IESEffectModel *)effect composerEffect:(id<AWEComposerEffectProtocol>)composerEffect source:(ACCPropSelectionSource)source;
- (instancetype)initWithEffect:(IESEffectModel *)effect source:(ACCPropSelectionSource)source;
- (IESEffectModel *)leafEffect;
@end
