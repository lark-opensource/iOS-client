//
//  ACCStickerGroupedApplyPredicate.h
//  AWEStudio-Pods-DouYin
//
//  Created by Howie He on 2020/8/17.
//

#import <Foundation/Foundation.h>
#import "ACCStickerApplyPredicate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerGroupedApplyPredicate : NSObject <ACCStickerApplyPredicate>

- (void)addSubPredicate:(id<ACCStickerApplyPredicate>)predicate;

@end

NS_ASSUME_NONNULL_END
