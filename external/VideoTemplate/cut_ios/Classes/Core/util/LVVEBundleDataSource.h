//
//  LVVEBundleDataSource.h
//  VideoTemplate
//
//  Created by ZhangYuanming on 2020/1/19.
//

#ifndef LVVEBundleDataSource_h
#define LVVEBundleDataSource_h

#import <Foundation/Foundation.h>
#include <cdom/ModelType.h>
#import "LVModelType.h"
#import "LVBundleDataSource.h"
#include <TemplateConsumer/Materials.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVVEBundleDataSourceProvider: NSObject

- (instancetype)initWithRootPath:(NSString *)rootPath;

- (NSString *)voiceEffectPath;

- (NSString *)videoAjustPathForType:(cdom::MaterialType)type payloadPath:(std::string)payloadPath resourceVersion:(std::string)version;

- (NSString *)systemFontFolder;

- (NSString *)taileaderReourcePath;

- (NSString *)taileaderAnimationPath;

- (NSString *)chromaPathWithPayloadPath:(std::string)payloadPath;

@end

@interface LVVEBundleDataSourceProvider(InnerResourceChecker)

+ (BOOL)checkExitInLocalDataSource:(cdom::MaterialType)materialType;

@end

NS_ASSUME_NONNULL_END

#endif /* LVVEBundleDataSource_h */
