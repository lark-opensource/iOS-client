//
//  DVECoreComposerBeautyProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/2/15.
//

#import <Foundation/Foundation.h>
#import "DVECoreProtocol.h"
#import "DVEEffectValue.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreComposerBeautyProtocol <DVECoreProtocol>

- (void)addOrUpdateBeautyWithEffectValue:(DVEEffectValue *)value
                              needCommit:(BOOL)commit;

- (void)deleteAllBeautyWithNeedCommit:(BOOL)commit;

- (NSArray *)currentBeautyIntensity;

@end

NS_ASSUME_NONNULL_END
