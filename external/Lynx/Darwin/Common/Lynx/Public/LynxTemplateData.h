// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXTEMPLATEDATA_H_
#define DARWIN_COMMON_LYNX_LYNXTEMPLATEDATA_H_

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

@interface LynxTemplateData : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithJson:(NSString *)json;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)updateWithJson:(NSString *)json;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

- (void)setObject:(id)object
          withKey:(NSString *)key __attribute__((deprecated("Use updateObject:forKey: instead.")));

- (void)updateObject:(id)object forKey:(NSString *)key;
- (void)updateBool:(BOOL)value forKey:(NSString *)key;
- (void)updateInteger:(NSInteger)value forKey:(NSString *)key;
- (void)updateDouble:(CGFloat)value forKey:(NSString *)key;

// will convert TemplateData to lepus value
- (void)updateWithTemplateData:(LynxTemplateData *)value;

- (BOOL)checkIsLegalData;

- (NSDictionary *)dictionary;

#pragma mark -preprocess
- (void)markState:(NSString *)name;

/**
 * TemplateData will be sync to Native. For Thread-Safety, we will clone the value in Native Side.
 * In some case, this may result in performance-loss, If your data won't change any more, Please
 * call this method to mark value Read-Only, so we'll no longer clone the value any more to improve
 * performance.
 */
- (void)markReadOnly;
- (BOOL)isReadOnly;

@end

#endif  // DARWIN_COMMON_LYNX_LYNXTEMPLATEDATA_H_
