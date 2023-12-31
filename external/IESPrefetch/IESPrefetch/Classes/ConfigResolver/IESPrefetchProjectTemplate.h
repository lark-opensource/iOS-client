//
//  IESPrefetchProjectTemplate.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchConfigTemplate.h"
#import "IESPrefetchOccasionTemplate.h"
#import "IESPrefetchRuleTemplate.h"
#import "IESPrefetchAPITemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchProjectTemplate : NSObject<IESPrefetchConfigTemplate>

@property (nonatomic, copy) NSString *project;
@property (nonatomic, copy) NSString *version;

@end

NS_ASSUME_NONNULL_END
