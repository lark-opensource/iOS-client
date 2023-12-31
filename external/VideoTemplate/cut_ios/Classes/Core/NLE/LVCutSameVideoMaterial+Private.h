//
//  LVCutSameVideoMaterial+Private.h
//  VideoTemplate-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import <TemplateConsumer/MaterialMiddleware.h>
#import "LVCutSameVideoMaterial.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVCutSameVideoMaterial (Conversion)
- (instancetype)initWithCPPModel:(std::shared_ptr<TemplateConsumer::VideoMaterial>)cppmodel;
- (std::shared_ptr<TemplateConsumer::VideoMaterial>)cppmodel;
@end

NS_ASSUME_NONNULL_END
