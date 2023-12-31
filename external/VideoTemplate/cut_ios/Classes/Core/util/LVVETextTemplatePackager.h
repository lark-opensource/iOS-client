//
//  LVVEEffectTemplatePackager.h
//  VideoTemplate
//
//  Created by Nemo on 2020/10/10.
//

#import <Foundation/Foundation.h>
#include <TemplateConsumer/TemplateModel.h>
#include <TemplateConsumer/Segment.h>
@class LVVEBundleDataSourceProvider;
NS_ASSUME_NONNULL_BEGIN

@interface LVVETextTemplatePackager : NSObject


+ (NSString *)dependResourceParamsOfSegment:(std::shared_ptr<CutSame::Segment>)segment inProject:(std::shared_ptr<CutSame::TemplateModel>)project;

+ (NSString *)textParamsOfSegment:(std::shared_ptr<CutSame::Segment>)segment bundleResource:(LVVEBundleDataSourceProvider *)bundleResource;

@end

NS_ASSUME_NONNULL_END
