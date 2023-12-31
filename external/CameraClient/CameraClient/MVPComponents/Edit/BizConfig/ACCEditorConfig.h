//
//  ACCEditorConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import "ACCEditorStickerConfigAssembler.h"
#import "ACCEditorMusicConfigAssembler.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface ACCEditorConfig : NSObject

// IMPORTANT!!! please ensure publish model's videoType canvasType duet parameters are configed
+ (instancetype)editorConfigWithPublishModelAndEnsurePublishModelIsConfiged:(nonnull AWEVideoPublishViewModel *)publishModel;

@property (nonatomic, strong, nonnull, readonly) ACCEditorStickerConfigAssembler *stickerConfigAssembler;
@property (nonatomic, strong, nonnull, readonly) ACCEditorMusicConfigAssembler *musicConfigAssembler;


- (CGRect)playerFrame;

- (instancetype)init NS_UNAVAILABLE;

- (void)prepareOnCompletion:(void (^)(NSError * _Nullable))completionHandler;

@end
