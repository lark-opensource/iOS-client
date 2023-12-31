//
//  IESPrefetchTemplateOutput.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/4.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchConfigTemplate.h"
#import "IESPrefetchAPIModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchTemplateInput : NSObject<IESPrefetchTemplateInput>

@end

@interface IESPrefetchTemplateOutput : NSObject<IESPrefetchTemplateOutput>

- (void)addRequestModel:(IESPrefetchAPIModel *)model;

@end

NS_ASSUME_NONNULL_END
