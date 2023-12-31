//
//  DVECustomResourceProvider.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/6/22.
//

#import <Foundation/Foundation.h>
#import "DVEUILayoutConfig.h"
#import "DVEConfig.h"
#import "DVEResourceManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVECustomResourceProvider : NSObject

#pragma mark - Init

+ (instancetype)shareManager;

@property (nonatomic, weak) id<DVEResourceManagerProtocol> resourceInterceptor;

#pragma mark - Register

- (void)registerBundle:(NSBundle *)bundle;

- (void)unRegisterBundle:(NSBundle *)bundle;

- (void)setExternalInjectBundle:(NSBundle *)bundle;

#pragma mark - Font Config

- (UIFont *)fontWithFontKey:(NSString *)fontKey
                    sizeKey:(NSString *)sizeKey;

#pragma mark - Color Config

- (UIColor *)colorWithKey:(NSString *)colorKey;

#pragma mark - Image Config

- (UIImage *)imageWithName:(NSString *)name;

#pragma mark - Layout Config

- (DVEUILayoutConfig *)layoutWithPositionName:(NSString * _Nullable)positionName
                                     sizeName:(NSString * _Nullable)sizeName
                                alignmentName:(NSString * _Nullable)alignmentName
                               edgeInsetsName:(NSString * _Nullable)edgeInsetsName
                                   enableName:(NSString * _Nullable)enableName;

- (NSInteger)layoutWithStyleName:(NSString *)styleName;

#pragma mark - NSString Config

- (NSString *)stringWithName:(NSString *)name;

#pragma mark - Bundle Config

- (NSBundle *)bundleWithName:(NSString *)name;

#pragma mark - Basic Config

- (DVEConfig *)configWithEnableName:(NSString * _Nullable)enableName;

#pragma mark - Converter

- (NSString *)colorValue:(NSString *)colorName;

- (NSString *)fontValue:(NSString *)fontName;

- (NSString *)layoutValue:(NSString *)layoutName;

#pragma mark - Other

- (nullable NSString *)pathForResource:(NSString * _Nullable)name
                                ofType:(NSString * _Nullable)ext;

#pragma mark - Clear

- (void)freeResource;

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
