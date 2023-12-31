//
//  IESEffectDefines.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import "IESEffectDefines.h"

NSString * const IESEffectPlatformSDKVersion = @"2.9.115";

NSString * const IES_FOLDER_PATH = @"com.bytedance.ies";
NSString * const IES_EFFECT_FOLDER_PATH = @"com.bytedance.ies/effect";
NSString * const IES_THIRDPARTY_FOLDER_PATH = @"com.bytedance.ies/thirdparty";
NSString * const IES_EFFECT_UNCOMPRESS_FOLDER_PATH = @"com.bytedance.ies/effect_uncompress";
NSString * const IES_EFFECT_ALGORITHM_FOLDER_PATH = @"com.bytedance.ies/effect_algorithm";
NSString * const IES_COMPOSER_EFFECT_FOLDER_PATH = @"com.bytedance.ies/effect_composer";

NSString * const IESEffectPlatformSDKErrorDomain = @"com.bytedance.ies.effect";
NSString * const IESEffectPlatformSDKAlgorithmModelErrorDomain = @"com.bytedance.ies.effect_algorithm";
NSString * const IESEffectNetworkResponse = @"IESEffectNetworkResponse";
NSString * const IESEffectNetworkResponseStatus = @"IESEffectNetworkResponseStatus";
NSString * const IESEffectNetworkResponseHeaderFields = @"IESEffectNetworkResponseHeaderFields";
NSString * const IESEffectErrorExtraInfoKey = @"IESEffectErrorExtraInfoKey";
NSString * const IESEffectType2DSticker = @"2DSticker";
NSString * const IESEffectType3DStikcer = @"3DSticker";
NSString * const IESEffectTypeMatting = @"Matting";
NSString * const IESEffectTypeFaceDistortion = @"FaceDistortion";
NSString * const IESEffectTypeFaceMakeup = @"FaceMakeup";
NSString * const IESEffectTypeHairColor = @"HairColor";
NSString * const IESEffectTypeFilter = @"Filter";
NSString * const IESEffectTypeFaceReshape = @"FaceReshape";
NSString * const IESEffectTypeBeauty = @"Beauty";
NSString * const IESEffectTypeBodyDance = @"BodyDance";
NSString * const IESEffectTypeFacePick = @"FacePick";
NSString * const IESEffectTypeParticleJoint = @"ParticleJoint";
NSString * const IESEffectTypeParticle = @"Particle";
NSString * const IESEffectTypeAR = @"AR";
NSString * const IESEffectTypeCat = @"2DStickerV2";
NSString * const IESEffectTypeARPhotoFace = @"PhotoFace";
NSString * const IESEffectTypeGame2D = @"Game2DV2";
NSString * const IESEffectTypeARKit = @"ARKit";
NSString * const IESEffectTypeFaceARKit = @"FaceARKit";
NSString * const IESEffectTypeTouchGes = @"TouchGes";
NSString * const IESEffectTypeMakeup = @"FaceMakeupV2";
NSString * const IESEffectTypeStabilizationOff = @"StabilizationOff";

__attribute__((constructor)) static void initialize()
{
    __autoreleasing NSArray *destinationArray = @[IES_EFFECT_FOLDER_PATH, IES_THIRDPARTY_FOLDER_PATH];
    for (NSString *path in destinationArray) {
        __autoreleasing NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [filePath stringByAppendingPathComponent:path];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}

NSString * IESEffectBookMarkPath()
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    });
    
    return [filePath stringByAppendingPathComponent:@"bookmark"];
}

NSString * IESEffectListPathWithAccessKey(NSString *accessKey)
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    });

    return [filePath stringByAppendingPathComponent:[@"effect-list" stringByAppendingFormat:@"-%@",accessKey]];
}


NSString * IESEffectListJsonPathWithAccessKey(NSString *accessKey)
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    });
  
    return [filePath stringByAppendingPathComponent:[@"effect-list-json-directory" stringByAppendingFormat:@"-%@",accessKey]];
}

NSString * IESMyEffectListPathWithAccessKey(NSString *accessKey)
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    });

    return [filePath stringByAppendingPathComponent:[@"my-effect-list" stringByAppendingFormat:@"-%@",accessKey]];
}

NSString * IESEffectPathWithIdentifier(NSString *identifier)
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    });

    return [filePath stringByAppendingPathComponent:identifier];
}

NSString * IESThirdPartyModelPathWithIdentifier(NSString *identifier)
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_THIRDPARTY_FOLDER_PATH];
    });
    
    return [filePath stringByAppendingPathComponent:identifier];
}

NSString * IESEffectUncompressPathWithIdentifier(NSString *identifier)
{
    static NSString *filePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_UNCOMPRESS_FOLDER_PATH];
    });
    
    return [filePath stringByAppendingPathComponent:identifier];
}

NSString * IESEffectSpeedTestPath(void)
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    return [filePath stringByAppendingPathComponent:@"speedtestresult"];
}

NSString * IESComposerResourceDir(void) {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:IES_COMPOSER_EFFECT_FOLDER_PATH];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return filePath;
}

NSString * IESComposerResourceZipDirWithMD5(NSString *md5) {
    NSString *filePath = [IESComposerResourceDir() stringByAppendingPathComponent:@"composer_zip"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (md5) {
        return [filePath stringByAppendingPathComponent:md5];
    } else {
        return filePath;
    }
}

NSString * IESComposerResourceUncompressDirWithMD5(NSString *md5) {
    NSString *filePath = [IESComposerResourceDir() stringByAppendingPathComponent:@"composer_uncompress"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (md5) {
        return [filePath stringByAppendingPathComponent:md5];
    } else {
        return filePath;
    }
}


NSDictionary * IESRequestLocationParametersProcessIfNeed(NSMutableDictionary *parameters) {
    [parameters removeObjectsForKeys:@[@"longitude", @"latitude",
                                       @"longitude_last", @"latitude_last"]];
    return [parameters copy];
}
