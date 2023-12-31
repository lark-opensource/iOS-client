//
//  IESEffectURLModel.h
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/9/27.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectURLModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *URI;
@property (nonatomic, copy) NSArray<NSString *> *originURLList;

- (NSArray<NSString *> *)URLList;

@end

NS_ASSUME_NONNULL_END
