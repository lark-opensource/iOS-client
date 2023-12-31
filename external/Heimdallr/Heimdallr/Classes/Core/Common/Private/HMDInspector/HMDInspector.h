//
//  HMDInspector.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/5/8.
//

#define LOCAL_ADDITIONAL_TABLE_NAME


#import <Foundation/Foundation.h>
#import "HeimdallrLocalModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDInspector : NSObject <HeimdallrLocalModule>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
