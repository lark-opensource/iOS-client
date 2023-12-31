//
//  DVECoreComposerFilterProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/2/16.
//

#import <Foundation/Foundation.h>
#import "DVECoreProtocol.h"
#import "DVEEffectValue.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreComposerFilterProtocol <DVECoreProtocol>

- (void)addOrUpdateFilterWithEffectValue:(DVEEffectValue *)value
                              needCommit:(BOOL)commit;

- (void)deleteCurrentFilterNeedCommit:(BOOL)commit;

- (NSDictionary *)currentFilterIntensity;

@end

NS_ASSUME_NONNULL_END
