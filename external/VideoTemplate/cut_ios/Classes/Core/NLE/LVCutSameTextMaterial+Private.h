//
//  LVCutSameTextMaterial+Private.h
//  VideoTemplate-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/25.
//

#import <Foundation/Foundation.h>
#import <TemplateConsumer/MaterialMiddleware.h>
#import "LVCutSameTextMaterial.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVCutSameTextMaterial (Conversion)
- (instancetype)initWithCPPModel:(std::shared_ptr<TemplateConsumer::TextMaterial>)cppmodel;
- (std::shared_ptr<TemplateConsumer::TextMaterial>)cppmodel;
@end

NS_ASSUME_NONNULL_END
