//
//  LVVETextPackagerHelper.h
//  VideoTemplate
//
//  Created by Lemonior on 2020/4/22.
//

#import <Foundation/Foundation.h>

@class LVMediaSegment;
@class LVVEBundleDataSourceProvider;
@class LVMediaDraft;

@interface LVVETextPackagerHelper : NSObject

+ (NSString *)genTextParametersSegment:(LVMediaSegment *)segment
                              rootPath:(NSString *)rootPath
                        bundleResource:(LVVEBundleDataSourceProvider *)bundleResource;


+ (NSString *)dependResourceParamsOfSegment:(LVMediaSegment *)segment inDraft:(LVMediaDraft *)draft;

+ (NSString *)textParamsOfSegment:(LVMediaSegment *)segment bundleResource:(LVVEBundleDataSourceProvider *)bundleResource;

@end
