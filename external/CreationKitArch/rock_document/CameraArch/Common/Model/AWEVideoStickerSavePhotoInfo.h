//Copyright © 2021 Bytedance. All rights reserved.

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoStickerSavePhotoInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSArray<NSString *> *photoNames;
@property (nonatomic, copy) NSString *toastText;
@property (nonatomic, copy) NSString *waterMarkPath;

@end

NS_ASSUME_NONNULL_END
