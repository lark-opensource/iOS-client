//
//  LVVETextPackager.h
//  VideoTemplate
//
//  Created by luochaojing on 2020/2/8.
//

#import <Foundation/Foundation.h>
#import <VideoTemplate/LVVEBundleDataSource.h>
#include <TemplateConsumer/MaterialText.h>
#include <TemplateConsumer/Segment.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVVETextPackager : NSObject

@property (nonatomic, copy, readonly) NSString *textPlaceHolder;

@property (nonatomic, copy, readonly) NSString *taileaderPlaceHolder;

+ (instancetype)shared;

+ (NSString *)genTextParametersSegment:(std::shared_ptr<CutSame::Segment>)segment rootPath:(NSString *)rootPath;

+ (NSString *)genTextParametersSegment:(std::shared_ptr<CutSame::Segment>)segment rootPath:(NSString *)rootPath bundleResource:(LVVEBundleDataSourceProvider *)bundleResource;

+ (void)setTextPlaceHolder:(NSString *)placeHolder;

+ (void)setTaileaderPlaceHolder:(NSString *)placeHolder;

/// 根据语言选择当前生效的系统字体包
/// @param folder系统字体文件夹，包含多个语言的系统字体包
+ (NSString *)systemFontAtCurrentLanguage:(NSString *)folder;

/// 文字渲染兜底的字体列表
/// @param folder系统字体文件夹，包含多个语言的系统字体包
+ (NSArray<NSString*>*)fallbackFontList:(NSString *)folder;

/// 根据文件夹找里面的字体文件
/// @param folder 文件夹路径
+ (NSString *)fontPathAtFolder:(NSString *)folder;

@end

NS_ASSUME_NONNULL_END
