//
//  DVEBusinessConfiguration.h
//  NLEEditor
//
//  Created by Lincoln on 2021/12/2.
//

#import <Foundation/Foundation.h>

#import <NLEPlatform/NLEModel+iOS.h>
#import <DVEFoundationKit/DVECommonDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEDraftModelProtocol, DVEVCContextExternalInjectProtocol, DVEResourcePickerModel;

@interface DVEBusinessConfiguration : NSObject

/// 当前业务类型
@property (nonatomic, assign) DVEBusinessType type;

/// 相册资源数组
@property (nonatomic, copy) NSArray<id<DVEResourcePickerModel>> *resources;

/// 草稿模型
@property (nonatomic, strong) id<DVEDraftModelProtocol> draftModel;

/// NLEModel
@property (nonatomic, strong) NLEModel_OC *nleModel;

/// 外部注入能力
@property (nonatomic, strong) id<DVEVCContextExternalInjectProtocol> injectService;

/// 模型资源文件夹
@property (nonatomic, copy) NSString *resourceDir;

@end

NS_ASSUME_NONNULL_END
