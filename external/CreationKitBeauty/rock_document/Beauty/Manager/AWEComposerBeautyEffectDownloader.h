//
//  AWEComposerBeautyEffectDownloader.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

FOUNDATION_EXTERN NSString *const kAWEComposerBeautyEffectUpdateNotification;

@interface AWEComposerBeautyEffectDownloader : NSObject

+ (AWEComposerBeautyEffectDownloader *)defaultDownloader;

- (void)downloadEffects:(NSArray *)effects;
- (AWEEffectDownloadStatus)downloadStatusOfEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)addEffectToDownloadQueue:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (BOOL)allEffectsDownloaded;

@end
