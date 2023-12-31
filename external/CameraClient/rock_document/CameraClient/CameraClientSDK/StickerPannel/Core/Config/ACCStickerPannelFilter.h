//
//  ACCStickerPannelFilter.h
//  Pods
//
//  Created by liyingpeng on 2020/8/23.
//

#ifndef ACCStickerPannelFilter_h
#define ACCStickerPannelFilter_h

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@protocol ACCStickerPannelFilter <NSObject>

// tags need to be filtered in pannel effects
- (NSArray<NSString *> *)filterTags;

- (BOOL)isIMPhoto;
- (BOOL)isAlbumImage;

- (BOOL)isCommerce;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCStickerPannelFilter_h */
