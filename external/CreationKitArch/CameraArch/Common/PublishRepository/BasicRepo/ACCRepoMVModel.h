//
//  ACCRepoMVModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

@class ACCMVAudioBeatTrackManager;

@interface ACCRepoMVModel : NSObject <NSCopying, ACCRepositoryContextProtocol>

@property (nonatomic, strong) id<ACCMusicModelProtocol> mvMusic;

@property (nonatomic, assign) NSInteger mvTemplateType;
@property (nonatomic, copy, nullable) NSString *templateModelId;
@property (nonatomic, copy, nullable) NSString *templateModelTip;
@property (nonatomic, assign) NSUInteger templateMaxMaterial;
@property (nonatomic, assign) NSUInteger templateMinMaterial;
@property (nonatomic, copy, nullable) NSString *templateMusicId;
@property (nonatomic, copy, nullable) NSString *templateMusicFileName;
@property (nonatomic, copy, nullable) NSArray<NSString *> *templateMaterials;

@property (nonatomic, copy) NSString *mvChallengeName;

//MV need enable origin sound,which determind the selectMusicPanel can refresh it's voiceSlider
@property (nonatomic, assign) BOOL enableOriginSoundInMV;

@property (nonatomic, copy) NSString *slideshowMVID;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<UIImage *> *> *serverExecutedImageDict;

@end

@interface AWEVideoPublishViewModel (RepoMV)
 
@property (nonatomic, strong, readonly) ACCRepoMVModel *repoMV;
 
@end

NS_ASSUME_NONNULL_END

