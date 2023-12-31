//
//  ACCBaseStickerView+ACCStickerCopying.h
//  CameraClient
//
//  Created by liuqing on 2020/6/15.
//

#import "ACCBaseStickerView.h"
#import "ACCStickerCopyingProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCBaseStickerView (ACCStickerCopying) <ACCStickerCopyingProtocol>

@property (nonatomic, copy) NSString *associationId;

@end

NS_ASSUME_NONNULL_END
