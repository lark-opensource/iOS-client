//
//   DVEUIFactory.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/24.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import "DVEVCContextExternalInjectProtocol.h"
#import "DVEDraftModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEUIFactory : NSObject

#pragma mark - Edit Page

#if ENABLE_MULTITRACKEDITOR
/// 通过资源模型和能力注入构造多轨剪辑页
/// @param resources 模型数组
/// @param injectService 外部注入能力
+ (UIViewController *)createDVEViewControllerWithResources:(NSArray<id<DVEResourcePickerModel>> *)resources
                                             injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

/// 通过草稿模型和能力注入构造多轨剪辑页
/// @param draft 草稿模型
/// @param injectService 外部注入能力
+ (UIViewController *)createDVEViewControllerWithDraft:(id<DVEDraftModelProtocol>)draft
                                         injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

/// 通过NLE模型和能力注入构造多轨剪辑页
/// @param model NLEModel
/// @param injectService 外部注入能力
+ (UIViewController *)createDVEViewControllerWithNLEModel:(NLEModel_OC *)model
                                            injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;
#endif
#if ENABLE_LITEEDITOR

/// 通过资源模型和能力注入构造轻剪辑页
/// @param resources 模型数组
/// @param injectService 外部注入能力
+ (UIViewController *)createDVELiteViewControllerWithResources:(NSArray<id<DVEResourcePickerModel>> *)resources
                                                 injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

/// 通过NLE模型和能力注入构造轻剪辑页
/// @param model NLEModel
/// @param resourceDir 模型资源文件夹
/// @param injectService 外部注入能力
+ (UIViewController *)createDVELiteViewControllerWithNLEModel:(NLEModel_OC *)model
                                                  resourceDir:(NSString *)resourceDir
                                                injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

#endif

#if ENABLE_TEMPLATETOOL

/// 通过模板模型和能力注入构造剪辑页
/// @param templateModel 模板模型
/// @param injectService 外部注入能力
+ (UIViewController *)createDVEViewControllerWithTemplateModel:(NLETemplateModel_OC *)templateModel
                                            injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

/// 通过模板模型和能力注入构造剪辑页
/// @param templateModel 模板模型
/// @param resourceDir 模型资源文件夹
/// @param injectService 外部注入能力
+ (UIViewController *)createDVEViewControllerWithTemplateModel:(NLETemplateModel_OC *)templateModel
                                               resourceDir:(NSString*)resourceDir
                                            injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

/// 通过资源和能力注入构造剪辑页
/// @param resources 资源列表
/// @param injectService 外部注入能力
+ (UIViewController *)createDVEViewControllerWithTemplateResources:(NSArray<id<DVEResourcePickerModel>> *)resources
                                                     injectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

#endif

#if ENABLE_DVEDRAFT_BOX
#pragma mark - Draft Page

/// 草稿管理页
/// @param injectService 外部注入能力
+ (UIViewController *) createDVEDraftViewControllerWithInjectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

/// 模板草稿管理页
/// @param injectService 外部注入能力
+ (UIViewController *) createDVETemplateDraftViewControllerWithInjectService:(id<DVEVCContextExternalInjectProtocol>)injectService;

#endif

@end


NS_ASSUME_NONNULL_END
