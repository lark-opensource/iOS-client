//
//  IESSimpleVideoModel.h
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/12/10.
//

#import <Mantle/Mantle.h>
#import "IESEffectURLModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESSimpleVideoModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) IESEffectURLModel *coverURL;
@property (nonatomic, copy, readonly) IESEffectURLModel *playURL;
@property (nonatomic, copy, readonly) NSString *groupID;

@end

NS_ASSUME_NONNULL_END
