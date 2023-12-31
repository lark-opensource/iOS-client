//
//  LKCustomExceptionConfig.h
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import <Foundation/Foundation.h>
#include "lk_section_data_utility.h"

#define LK_CEXC_CONFIG(name) LK_SECTION_DATA_REGISTER(LKCExcption,name)

NS_ASSUME_NONNULL_BEGIN

@protocol LKCExceptionProtocol;

@interface LKCustomExceptionConfig : NSObject

+ (NSArray *)getAllRegistExceptionClass;
+ (NSString *)configKey;
- (id<LKCExceptionProtocol>)getCustomException;
- (instancetype)initWithDictionary:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
