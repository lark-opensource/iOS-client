//
//  ACCENVProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/30.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCENVType) {
    ACCENVONline = 0,
    ACCENVTest,
    ACCENVDebug,
    ACCENVBeta,
    ACCENVSaf,
};


#define ACC_ENV_IS_TEST    ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVTest)
#define ACC_ENV_IS_DEBUG   ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVDebug)
#define ACC_ENV_IS_BETA    ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVBeta)

@protocol ACCENVProtocol <NSObject>

@optional

/*
 * Current environment
 */
- (ACCENVType)currentEnv;

/*
* First use after upgrade
*/
- (BOOL)isFirstLaunchAfterUpdating;

@end

NS_ASSUME_NONNULL_END
