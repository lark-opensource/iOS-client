//
//  LVVideoMaterialUtil.h
//  VideoTemplate
//
//  Created by maycliao on 2021/3/30.
//

#import <Foundation/Foundation.h>
#include <TemplateConsumer/Segment.h>
#include <cdom/ModelType.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVVideoMaterialUtil : NSObject

+ (BOOL)hasSeparatedAudio:(std::shared_ptr<CutSame::Segment>)segment;

@end

NS_ASSUME_NONNULL_END
