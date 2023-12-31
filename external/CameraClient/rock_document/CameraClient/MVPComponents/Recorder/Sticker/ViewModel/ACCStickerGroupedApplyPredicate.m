//
//  ACCStickerGroupedApplyPredicate.m
//  AWEStudio-Pods-DouYin
//
//  Created by Howie He on 2020/8/17.
//

#import "ACCStickerGroupedApplyPredicate.h"

@interface ACCStickerGroupedApplyPredicate ()

@property (nonatomic) NSHashTable<id<ACCStickerApplyPredicate>> *predicates;

@end

@implementation ACCStickerGroupedApplyPredicate

- (instancetype)init
{
    self = [super init];
    if (self) {
        _predicates = [NSHashTable hashTableWithOptions:(NSPointerFunctionsWeakMemory)];
    }
    return self;
}

- (BOOL)shouldApplySticker:(nonnull IESEffectModel *)sticker error:(NSError **)error {
    BOOL shouldApply = YES;
    for (id<ACCStickerApplyPredicate> predicate in self.predicates) {
        shouldApply &= [predicate shouldApplySticker:sticker error:error];
        if (!shouldApply) {
            return NO;
        }
    }
    return shouldApply;
}

- (void)addSubPredicate:(id<ACCStickerApplyPredicate>)predicate
{
    [self.predicates addObject:predicate];
}

@end
