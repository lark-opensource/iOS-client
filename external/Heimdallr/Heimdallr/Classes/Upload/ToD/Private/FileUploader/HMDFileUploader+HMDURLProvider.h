//
//  HMDFileUploader+HMDURLProvider.h
//  AppHost-HeimdallrFinder-Unit-Tests
//
//  Created by Nickyo on 2023/8/18.
//

#import "HMDFileUploader.h"
// PrivateServices
#import "HMDURLProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDFileUploader (HMDURLProvider) <HMDURLHostProvider>

@end

NS_ASSUME_NONNULL_END
