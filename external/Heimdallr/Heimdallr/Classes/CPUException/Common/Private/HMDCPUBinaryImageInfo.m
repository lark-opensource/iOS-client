//
//  HMDCPUBinaryImageManager.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/12.
//

#import "HMDCPUBinaryImageInfo.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDBinaryImage.h"

NSString *const kHMDCallTreeNodeImageName = @"image_name";
NSString *const kHMDCallTreeImageUUID = @"image_uuid";
NSString *const kHMDCallTreeImagePath = @"image_path";
NSString *const kHMDCallTreeImageIsMainBinary = @"is_main_binary";
NSString *const kHMDCallTreeImageCPUArch = @"cpu_arch";

@interface HMDCPUBinaryImageInfo ()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *binaryMap;
@property (nonatomic, assign, readwrite) BOOL isBinaryLoad;
@property (nonatomic, strong) NSMutableDictionary *cpuArchMap;

@end

@implementation HMDCPUBinaryImageInfo


- (void)loadBinaryImage {
    if (self.binaryMap.count > 0) { return ; }
    NSMutableDictionary *imageUUIDMap = [NSMutableDictionary dictionary];
    [HMDBinaryImage enumerateImagesUsingBlock:^(HMDBinaryImage *imageInfo){
        NSString *imageUUID = imageInfo.uuid;
        NSString *imagePath = imageInfo.path;
        NSString *cpuArch = [self getCPUArchWithMajor:imageInfo.cpuType minor:imageInfo.cpuSubType];
        BOOL isMainBinary = imageInfo.isExecutable;
        NSDictionary *infoDict = @{
            kHMDCallTreeImageUUID: imageUUID ?: @"",
            kHMDCallTreeImagePath: imagePath ?: @"",
            kHMDCallTreeImageIsMainBinary: @(isMainBinary),
            kHMDCallTreeImageCPUArch: cpuArch ?: @"",
        };
        [imageUUIDMap hmd_setSafeObject:infoDict forKey:imageInfo.name];
    }];
    self.isBinaryLoad = YES;
    self.binaryMap = imageUUIDMap;
}

- (NSDictionary *)getBinaryImage:(HMDCPUExceptionImageName)imageName {
    if (!self.isBinaryLoad) {
        [self loadBinaryImage];
    }
    NSDictionary *imageInfo = [self.binaryMap hmd_objectForKey:imageName class:[NSDictionary class]];
    return imageInfo;
}

- (nullable NSDictionary<HMDCPUExceptionImageName,NSDictionary *> *)getBinaryImagesWithBinaryImages:(NSArray<HMDCPUExceptionImageName> *)imageNames {
    NSMutableDictionary *binaryImageDicts = [NSMutableDictionary dictionary];
    if (!self.isBinaryLoad) {
        [self loadBinaryImage];
    }

    for (HMDCPUExceptionImageName curName in imageNames) {
        NSDictionary *imageInfo = [self.binaryMap hmd_objectForKey:curName class:[NSDictionary class]];
        [binaryImageDicts hmd_setObject:imageInfo forKey:curName];
    }

    return [binaryImageDicts copy];
}

- (nullable NSString *)getCPUArchWithMajor:(cpu_type_t)majorCode minor:(cpu_subtype_t)minorCode {
    if (!self.cpuArchMap) {
        self.cpuArchMap = [NSMutableDictionary dictionary];
    }
    NSString *searchKey = [NSString stringWithFormat:@"%d+%d", majorCode, minorCode];
    NSString *cpuArch = [self.cpuArchMap hmd_objectForKey:searchKey class:NSString.class];
    if (!cpuArch) {
        cpuArch = [HMDInfo CPUArchForMajor:majorCode minor:minorCode];
        [self.cpuArchMap hmd_setSafeObject:cpuArch forKey:searchKey];
    }
    return cpuArch;
}

@end
