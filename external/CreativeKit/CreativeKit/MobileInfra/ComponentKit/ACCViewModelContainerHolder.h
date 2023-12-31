//
//  ACCComponentOwner.h
//  AAWELaunchOptimization
//
//  Created by leo on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import "ACCViewModelContainer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCViewModelContainerHolder <NSObject>
- (ACCViewModelContainer *)viewModelContainer;
@end

NS_ASSUME_NONNULL_END
