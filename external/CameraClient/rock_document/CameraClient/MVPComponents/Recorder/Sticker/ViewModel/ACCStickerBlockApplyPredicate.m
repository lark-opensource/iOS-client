//
//  ACCStickerBlockApplyPredicate.m
//  AWEStudio-Pods-DouYin
//
//  Created by Howie He on 2020/8/17.
//

#import "ACCStickerBlockApplyPredicate.h"

@interface ACCStickerBlockApplyPredicate ()

@property (nonatomic, copy) BOOL(^predicate)(IESEffectModel *, NSError **error);
@end

@implementation ACCStickerBlockApplyPredicate

- (instancetype)initWithPredicate:(BOOL (^)(IESEffectModel * _Nonnull effect, NSError *__autoreleasing  _Nullable * _Nullable))predicate
{
    if (self = [super init]) {
        _predicate = predicate;
    }
    return self;
}

- (BOOL)shouldApplySticker:(nonnull IESEffectModel *)sticker
                     error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    return self.predicate(sticker, error);
}

@end
