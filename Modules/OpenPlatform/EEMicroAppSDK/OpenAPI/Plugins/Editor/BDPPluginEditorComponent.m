//
//  BDPPluginEditorComponent.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/6/24.
//

#import "BDPPluginEditorComponent.h"
#import <TTMicroApp/BDPAppPage.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/TMASessionManager.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <LarkStorage/LarkStorage-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation BDPPluginEditorComponent

#pragma mark - Initialize
/*-----------------------------------------------*/
//             Initialize - 初始化相关
/*-----------------------------------------------*/

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

#pragma mark - JSBridge
//  Editor私有接口
- (void)editorFilePathConvertWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback engine:(BDPJSBridgeEngine)engine controller:(UIViewController *)controller {
    NSArray <NSString *> *imageUrlArray = [param bdp_arrayValueForKey:@"images"];
    if (![imageUrlArray.firstObject isKindOfClass:NSString.class]) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"param error, images is invalid")
        return;
    }
    NSArray <EditorPickImage *> *images = [self getImagesFromUrls:imageUrlArray];
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, BDPTypeNativeApp);
    NSMutableArray *imageFiles = [[NSMutableArray alloc] initWithCapacity:images.count];
    [images enumerateObjectsUsingBlock:^(EditorPickImage * _Nonnull pickImage, NSUInteger idx, BOOL * _Nonnull stop) {
        //  limitSize   要大一点
        NSData *imageData = [EditorImageUtil dataForImage:pickImage quality:1 limitSize:NSUIntegerMax];
        //Destination AbsPath
        NSString *tmpPath = nil;
        NSString *fileExtension = [TMACustomHelper contentTypeForImageData:imageData];
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:engine.uniqueID];

        OPFileObject *fileObj = [OPFileObject generateRandomTTFile:BDPFolderPathTypeTemp fileExtension:fileExtension];
        OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:engine.uniqueID
                                                                                 trace:nil
                                                                                   tag:@"editorFilePathConvert"];

        NSError *error = nil;
        BOOL result = [OPFileSystemCompatible writeSystemData:imageData to:fileObj context:fsContext error:&error];
        if (!result || error) {
            fsContext.trace.error(@"write systemData failed, result: %@, error: %@", @(result), error.description);
            return;
        }
        [imageFiles addObject:@{
            @"filePath": fileObj.rawValue,
            @"width" : @(pickImage.image.size.width * pickImage.image.scale / UIScreen.mainScreen.scale),
            @"height" : @(pickImage.image.size.height * pickImage.image.scale / UIScreen.mainScreen.scale)
        }];
    }];
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"images": imageFiles})
}

- (NSArray <EditorPickImage *> *)getImagesFromUrls:(NSArray <NSString *> *)urls {
    NSMutableArray *images = NSMutableArray.array;
    for (NSString *url in urls) {
        NSData * data = [NSData lss_dataWithContentsOfURL:[NSURL URLWithString:url] error:nil];
        UIImage *result = [UIImage imageWithData:data];
        if (result) {
            EditorPickImage *i = [[EditorPickImage alloc] initWithImage:result data:nil];
            [images addObject:i];
        }
    }
    return images;
}

@end

