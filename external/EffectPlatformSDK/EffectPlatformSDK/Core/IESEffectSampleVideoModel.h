//
//  IESEffectSampleVideoModel.h
//  EffectPlatformSDK
//
//  Created by Fengfanhua.byte on 2021/9/27.
//

#import <Mantle/Mantle.h>
#import "IESEffectURLModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectSampleVideoModel : MTLModel<MTLJSONSerializing>

// from net
@property (nonatomic, copy, readonly) IESEffectURLModel *coverURL;
@property (nonatomic, copy, readonly) IESEffectURLModel *playURL;
@property (nonatomic, copy, readonly) IESEffectURLModel *h264URL;
@property (nonatomic, copy, readonly) IESEffectURLModel *downloadURL;
@property (nonatomic, copy, readonly) IESEffectURLModel *dynamicCover;

@property (nonatomic, copy, readonly) NSNumber *height;
@property (nonatomic, copy, readonly) NSNumber *width;

@end

NS_ASSUME_NONNULL_END
