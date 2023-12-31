//
//  AWEStickerMusicManager.h
//  Pods
//
//  Created by homeboy on 2019/8/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerMusicManager : NSObject

+ (void)setForceBindMusicDownloadFailedWithEffectIdentifier:(NSString *)effectIdentifier;

+ (BOOL)getForceBindMusicDownloadFailed:(NSString *)effectID;

+ (void)initializeForceBindMusicDownloadFailed;

+ (BOOL)musicIsForceBindStickerWithExtra:(NSString *)extra;

@end

NS_ASSUME_NONNULL_END
