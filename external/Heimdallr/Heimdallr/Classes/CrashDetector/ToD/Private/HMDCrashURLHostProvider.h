//
//  HMDCrashURLHostProvider.h
//  Heimdallr
//
//  Created by Nickyo on 2023/8/1.
//

#if !SIMPLIFYEXTENSION

#import "HMDCrashTracker.h"
// PrivateServices
#import "HMDURLProvider.h"

@interface HMDCrashTracker (HMDURLHostProvider) <HMDURLHostProvider>

@end

#endif /* SIMPLIFYEXTENSION */
