//
//  NLESegmentSticker_OC+ACCAdditions.h
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import <NLEPlatform/NLESegmentSticker+iOS.h>
#import <CreationKitArch/ACCStickerMigrationProtocol.h>
typedef NS_ENUM(NSUInteger, ACCCrossPlatformStickerType);

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentSticker_OC (ACCAdditions)

@property (nonatomic, assign) ACCCrossPlatformStickerType stickerType;

@property (nonatomic, strong) NSMutableDictionary *extraDict;

@end

NS_ASSUME_NONNULL_END
