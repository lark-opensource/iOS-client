//
//  MVPBaseServiceContainer+DVEInject.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/2/15.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MVPBaseServiceContainer+DVEInject.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <DVEFoundationKit/DVEMacros.h>
#import <TTVideoEditor/UIColor+Utils.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation MVPBaseServiceContainer (MVPBaseServiceContainer_DVEInject)

/// 资源加载能力
- (id<DVEResourceLoaderProtocol>)provideResourceLoader {
    return [[DVEResourceLoader alloc] init];
}

- (id<DVELiteEditorInjectionProtocol>)provideLiteEditorInjection {
    return [[DVELiteEditorInjectionImpl alloc] init];;
}

@end

@implementation DVELiteEditorInjectionImpl

- (UIView<DVELiteBottomFunctionalViewActionProtocol> *)bottomFunctionalView {
    CGFloat xOffset = [[UIScreen mainScreen] bounds].size.width - 84;
    UIViewController* camera = [MVPBaseServiceContainer sharedContainer].camera;
    UIViewController* editing = [MVPBaseServiceContainer sharedContainer].editing;

    if (camera != NULL && camera.view.window != NULL) {
        xOffset = camera.view.window.bounds.size.width - 84;
    } else if (editing != NULL) {
        xOffset = editing.view.bounds.size.width - 84;
    }
    CGFloat dveWidth = DVEScreenWidth();
    if (dveWidth > 0) {
        xOffset = dveWidth - 84;
    }
    DVEBottomView* view = [[DVEBottomView alloc] initWithFrame:CGRectMake(xOffset, 0, 68, 36)];
    view.backgroundColor = [UIColor colorWithHex:0x4C88FF];
    [view setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [view.layer setMasksToBounds:YES];
    [view.layer setCornerRadius:6];
    [view.titleLabel setFont:[UIFont systemFontOfSize:16]];
    if ([MVPBaseServiceContainer sharedContainer].inCamera) {
        [view setTitle:[LVDCameraI18N getLocalizedStringWithKey:@"message_send" defaultStr:NULL] forState:UIControlStateNormal];
    } else {
        [view setTitle:[LVDCameraI18N getLocalizedStringWithKey:@"message_finish" defaultStr:NULL] forState:UIControlStateNormal];
    }
    [view addTarget:[MVPBaseServiceContainer sharedContainer] action:@selector(clickSendBtn:) forControlEvents:UIControlEventTouchUpInside];
    return view;
}

- (void)willCloseLiteEditor:(DVEVCContext *)vcContext {
    id<DVECoreDraftServiceProtocol> draftService = IESAutoInline(vcContext.serviceProvider,DVECoreDraftServiceProtocol);
    [draftService clearAllCache:NULL];
}

@end

@implementation DVEBottomView

- (void)bottomFunctionalView:(UIView<DVELiteBottomFunctionalViewActionProtocol> *)view
         didChangeScreenSize:(CGSize)newSize {
    CGFloat xOffset = newSize.width - 84;
    CGRect frame = view.frame;
    view.frame = CGRectMake(xOffset, frame.origin.y, frame.size.width, frame.size.height);
}

@end

static NSArray<VEResourceCategoryModel*>* filterModels;
static BOOL checkStickerUpdate = NO;
static BOOL checkBeautyUpdate = NO;
static BOOL checkFilterUpdate = NO;

@implementation DVEResourceLoader

/// 轻剪辑滤镜分类
- (void)liteFilterCategory:(DVEResourceCategoryLoadHandler)hander {
    IESEffectPlatformResponseModel * model = [EffectPlatform cachedEffectsOfPanel:@"filter"];
    if (checkStickerUpdate && model) {
        [self transformFilterModel:model handler:hander];
        return;
    }
    __weak typeof(self) wself = self;
    if (!model) {
        [EffectPlatform downloadEffectListWithPanel:@"filter" saveCache:YES  completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
            __strong typeof(wself) sself = wself;
            if (response) {
                [sself transformFilterModel:response handler:hander];
            }
        }];
    } else {
        [EffectPlatform checkEffectUpdateWithPanel:@"filter" completion:^(BOOL needUpdate) {
            checkStickerUpdate = YES;
            if (!needUpdate && model) {
                __strong typeof(wself) sself = wself;
                [sself transformFilterModel:model handler:hander];
                return;
            }
            [EffectPlatform downloadEffectListWithPanel:@"filter" saveCache:YES  completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                __strong typeof(wself) sself = wself;
                if (response) {
                    [sself transformFilterModel:response handler:hander];
                }
            }];
        }];
    }
}

- (void)transformFilterModel:(IESEffectPlatformResponseModel *)model handler: (DVEResourceModelLoadHandler)handler {
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:model.categories.count];
     for (IESCategoryModel * cm in model.categories) {
         VEResourceCategoryModel* categoryModel = [[VEResourceCategoryModel alloc] init];
         categoryModel.categoryId = cm.categoryIdentifier;
         categoryModel.name = cm.categoryName;

         NSMutableArray *models = [NSMutableArray arrayWithCapacity:cm.effects.count];
         for (IESEffectModel * m in cm.effects) {
             VEResourceModel *eValue = [self transform:m tagConfig:@"filterconfig"];
             [models addObject:eValue];
         }
         categoryModel.models = models;
         [categories addObject:categoryModel];
     }
    filterModels = categories;
    handler(categories, NULL);
}

/// 轻剪辑滤镜分类下的具体数据
/// @param category 现有分类数据
/// @param hander 刷新回调
- (void)liteFilterModel:(id<DVEResourceCategoryModelProtocol>)category
                handler:(DVEResourceModelLoadHandler)hander {

    for (VEResourceCategoryModel * c in filterModels) {
        if ([category.name isEqualToString: c.name]) {
            hander(c.models, NULL);
            return;
        }
    }
}

- (void)textColorModel:(DVEResourceModelLoadHandler)hander {
    NSArray* collors = @[
        @[@0.941, @0.356, @0.337, @1],
        @[@1, @1, @1, @1],
        @[@0.102, @0.102, @0.102, @1],
        @[@0.329, @0.76, @0.282, @1],
        @[@0.98, @0.784, @0.137, @1],
        @[@0.298, @0.533, @1, @1],
        @[@0.89, @0.321, @0.639, @1],
    ];
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:[collors count]];
    for (NSArray *collor in collors) {
      VEResourceModel *model = [[VEResourceModel alloc] init];
      model.name = @"";
      model.identifier = model.name;
      model.sourcePath = @"";
      model.color = collor;
      [models dve_addObject:model];
    }
    hander(models, NULL);
}

/// 轻剪辑美颜资源
- (void)liteBeautyModel:(DVEResourceModelLoadHandler)hander {
    IESEffectPlatformResponseModel * model = [EffectPlatform cachedEffectsOfPanel:@"beauty"];
    if (checkStickerUpdate && model) {
        [self transformBeautyModel:model handler:hander];
        return;
    }
    __weak typeof(self) wself = self;
    if (!model) {
        [EffectPlatform downloadEffectListWithPanel:@"beauty" saveCache:YES  completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
            __strong typeof(wself) sself = wself;
            if (response) {
                [sself transformBeautyModel:response handler:hander];
            }
        }];
    } else {
        [EffectPlatform checkEffectUpdateWithPanel:@"beauty" completion:^(BOOL needUpdate) {
            checkStickerUpdate = YES;
            if (!needUpdate && model) {
                __strong typeof(wself) sself = wself;
                [sself transformBeautyModel:model handler:hander];
                return;
            }
            [EffectPlatform downloadEffectListWithPanel:@"beauty" saveCache:YES  completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                __strong typeof(wself) sself = wself;
                if (response) {
                    [sself transformBeautyModel:response handler:hander];
                }
            }];
        }];
    }
}

- (void)transformBeautyModel:(IESEffectPlatformResponseModel *)model handler: (DVEResourceModelLoadHandler)handler {
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:model.effects.count];
    for (IESEffectModel * m in model.effects) {
        VEResourceModel* eValue = [self transform:m tagConfig:@"beautify"];
        [models addObject:eValue];
    }
    handler(models, NULL);
}

///轻剪辑表情贴纸列表
- (void)liteEmojiStickerModel:(DVEResourceModelLoadHandler)handler {
    IESEffectPlatformResponseModel * model = [EffectPlatform cachedEffectsOfPanel:@"sticker"];
    if (checkStickerUpdate && model) {
        [self transformStickerModel:model handler:handler];
        return;
    }
    __weak typeof(self) wself = self;
    if (!model) {
        [EffectPlatform downloadEffectListWithPanel:@"sticker" saveCache:YES  completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
            __strong typeof(wself) sself = wself;
            if (response) {
                [sself transformStickerModel:response handler:handler];
            }
        }];
    } else {
        [EffectPlatform checkEffectUpdateWithPanel:@"sticker" completion:^(BOOL needUpdate) {
            checkStickerUpdate = YES;
            if (!needUpdate && model) {
                __strong typeof(wself) sself = wself;
                [sself transformStickerModel:model handler:handler];
                return;
            }
            [EffectPlatform downloadEffectListWithPanel:@"sticker" saveCache:YES  completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                __strong typeof(wself) sself = wself;
                if (response) {
                    [sself transformStickerModel:response handler:handler];
                }
            }];
        }];
    }
}

- (void)transformStickerModel:(IESEffectPlatformResponseModel *)model handler: (DVEResourceModelLoadHandler)handler {
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:model.effects.count];
    for (IESEffectModel * m in model.effects) {
        VEResourceModel* eValue = [self transform:m tagConfig:@""];
        [models addObject:eValue];
    }
    handler(models, NULL);
}

- (VEResourceModel *)transform:(IESEffectModel *)model tagConfig:(NSString *)configKey {
    VEResourceModel *eValue = [[VEResourceModel alloc] init];
    eValue.model = model;
    eValue.name = model.effectName;
    eValue.identifier = model.sourceIdentifier;
    eValue.resourceId = model.resourceId;
    eValue.imageURL = [NSURL URLWithString:model.iconDownloadURLs.firstObject];
    eValue.resourceTag = DVEResourceTagNormal;
    eValue.sourcePath = model.filePath;
    NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];
    NSError *error = nil;
    NSData* data = [model.extra dataUsingEncoding:NSUTF8StringEncoding];
    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSString* config = result[configKey];
        NSData* configData = [config dataUsingEncoding:NSUTF8StringEncoding];
        if (configData != NULL) {
            result = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingAllowFragments error:&error];
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSArray* items= result[@"items"];
                for (NSDictionary * item in items) {
                    tags[item[@"tag"]] = @0;
                    NSNumber* value = item[@"value"];
                    if ([value isKindOfClass:[NSNumber class]] &&
                        [value floatValue] > 0) {
                        eValue.defaultValue = [value floatValue] / 100;
                    }
                }
            }
        }
    }
    eValue.effectTags = tags;
    return eValue;
}

@end

@implementation VEResourceCategoryModel

@synthesize models;
@synthesize name;
@synthesize order;
@synthesize categoryId;

@end

@implementation VEResourceModel

@synthesize imageURL;
@synthesize name;
@synthesize sourcePath;
@synthesize assetImage;
@synthesize identifier;
@synthesize resourceId;

@synthesize stickerType;
@synthesize alignType;
@synthesize color;
@synthesize overlap;
@synthesize style;
@synthesize typeSettingKind;
@synthesize textTemplateDeps;
@synthesize resourceTag;
@synthesize canvasType;
@synthesize mask;
@synthesize effectTags;
@synthesize effectExtra;
@synthesize speedPoints;
@synthesize defaultValue;

///资源状态
- (DVEResourceModelStatus)status
{
    if (self.sourcePath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:self.sourcePath]) {
        return DVEResourceModelStatusDefault;
    }
    if (self.downloading) {
        return DVEResourceModelStatusDownloding;
    }
    return DVEResourceModelStatusNeedDownlod;
}

-(void)downloadModel:(void(^)(id<DVEResourceModelProtocol> model))handler {
    self.downloading = true;
    __weak typeof(self) wself = self;
    [EffectPlatform downloadEffect:self.model progress:^(CGFloat progress) {
        } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        __strong typeof(wself) sself = wself;
        if (error) {
            [LVDCameraToast showFailedWithMessage:[LVDCameraI18N getLocalizedStringWithKey:@"download_model_failed" defaultStr:nil] on: [LVDCameraAlert currentWindow]];
        }
        sself.sourcePath = filePath;
        sself.downloading = false;
        handler(sself);
    }];
}

@end
