//
//  ACCSpecialEffectViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/8/7.
//

#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCEditSpecialEffectServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCSpecialEffectViewModel : ACCEditViewModel <ACCEditSpecialEffectServiceProtocol>

- (void)sendWillDismissVCSignal;

@end

NS_ASSUME_NONNULL_END
