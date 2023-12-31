//
//  BDPChooseImagePluginModel.m
//  Timor
//
//  Created by 武嘉晟 on 2019/11/19.
//

#import "BDPChooseImagePluginModel.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

static NSString *const kBDPCameraDeviceFront = @"front";
static NSString *const kBDPCameraDeviceBack = @"back";

@implementation BDPChooseImagePluginModel

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    if (self = [super initWithDictionary:dict error:err]) {
        if (![self.cameraDevice isEqualToString:kBDPCameraDeviceBack] && ![self.cameraDevice isEqualToString:kBDPCameraDeviceFront]) {
            self.cameraDevice = kBDPCameraDeviceBack;
        }
    }
    return self;
}

@end

