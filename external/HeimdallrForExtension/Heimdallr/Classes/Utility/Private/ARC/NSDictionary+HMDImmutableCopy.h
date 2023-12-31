//
//  NSDictionary+HMDImmutableCopy.h
//  Heimdallr
//
//  Created by 崔晓兵 on 24/4/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (HMDImmutableCopy)

- (NSDictionary *)hmd_immutableCopy;

@end


@interface NSDictionary (HMDHasMutableContent)

- (BOOL)hmd_hasMutableContainer;

@end

NS_ASSUME_NONNULL_END
