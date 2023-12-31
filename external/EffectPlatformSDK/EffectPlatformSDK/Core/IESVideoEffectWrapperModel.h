//
//  IESVideoEffectWrapperModel.h
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/12/10.
//

#import <Mantle/Mantle.h>
#import "IESEffectModel.h"
#import "IESSimpleVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESVideoEffectWrapperModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) IESEffectModel *effect;
@property (nonatomic, copy, readonly) IESSimpleVideoModel *video;

@end

NS_ASSUME_NONNULL_END
