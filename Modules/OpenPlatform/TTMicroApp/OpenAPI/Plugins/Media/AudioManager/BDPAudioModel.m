//
//  BDPAudioModel.m
//  Timor
//
//  Created by muhuai on 2018/2/1.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "BDPAudioModel.h"
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPCommonManager.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

#define BDPAudioFloatWindowSence @"011018"
#define BDPAudioFloatWindowLaunchFrom @"voice_component"
#define BDPAudioFloatWindowLocation @"float_window"

@interface BDPAudioModel()
@property (nonatomic, strong, readwrite) NSURL *backScheme;
@end

@implementation BDPAudioModel

/*-----------------------------------------------*/
//        JSON Initialize - JSON初始化相关
/*-----------------------------------------------*/
+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName
{
    return NO;
}

#pragma mark - Initilizer
- (instancetype)initWithDictionary:(NSDictionary *)dic uniqueID:(BDPUniqueID *)uniqueID error:(NSError *__autoreleasing *)error
{
    if (self = [super initWithDictionary:dic error:error]) {
        OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:self.src];
        OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:uniqueID
                                                                                 trace:nil
                                                                                   tag:@"audio"
                                                                           isAuxiliary:YES];
        if (!fileObj) {
            fsContext.trace.error(@"resolve fileobj failed");
        }
        NSError *fsError = nil;
        NSString *fileSystemPath = [OPFileSystemCompatible getSystemFileFrom:fileObj context:fsContext error:&fsError];
        if (fsError) {
            fsContext.trace.error(@"getSystemFilePath failed, hasFileSystemPath: %@, error: %@", @(fileSystemPath != nil), fsError.description);
        } else {
            NSString *srcPath = [NSURL fileURLWithPath:fileSystemPath].absoluteString;
            self.src = srcPath;
        }
        self.relativeSrc = [self.src hasPrefix:@"./"] ? [self.src substringFromIndex:2] : self.src;
        self.isInPkg = false; // 对比 setAudioState 逻辑，当pkg路径被 filesystem 解析为 auxiliary 时需要设置为 false，完成收敛灰度后，删除旧逻辑且不再需要此字段

        //初始化scheme
        BDPSchemaCodecOptions *schemaOptions = [[BDPSchemaCodecOptions alloc]init];
        [schemaOptions setProtocol:@"sslocal"];
        [schemaOptions setHost:SCHEMA_APP];
        [schemaOptions setAppID:uniqueID.appID];
        [schemaOptions setVersionType:uniqueID.versionType];
        [schemaOptions setPath:[self.audioPage bdp_stringValueForKey:@"path"]];
        [schemaOptions setQuery:[[self.audioPage bdp_dictionaryValueForKey:@"query"] mutableCopy]];
        //埋点相关
        [schemaOptions setScene:BDPAudioFloatWindowSence];
        [schemaOptions setBdpLog:[@{BDPSchemaBDPLogKeyLaunchFrom:BDPAudioFloatWindowLaunchFrom,BDPSchemaBDPLogKeyLocation:BDPAudioFloatWindowLocation} mutableCopy]];
        
        self.backScheme = [BDPSchemaCodec schemaURLFromCodecOptions:schemaOptions error:error];
        if (!self.backScheme && error) {
            return nil;
        }
    }
    return self;
}

@end
