//
//  BDXBridgeChooseMediaMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeChooseMediaMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeChooseMediaMethod

- (NSString *)methodName
{
    return @"x.chooseMedia";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeChooseMediaMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeChooseMediaMethodResultModel.class;
}

@end

@implementation BDXBridgeChooseMediaMethodParamModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxCount = @(1);
        _saveToPhotoAlbum = NO;
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"maxCount": @"maxCount",
        @"mediaTypes": @"mediaTypes",
        @"sourceType": @"sourceType",
        @"cameraType": @"cameraType",
        @"compressImage": @"compressImage",
        @"saveToPhotoAlbum": @"saveToPhotoAlbum",
        @"needBinaryData": @"needBinaryData",
        @"compressWidth" : @"compressWidth",
        @"compressHeight" : @"compressHeight",
        @"isNeedCut" : @"isNeedCut",
        @"cropRatioWidth" : @"cropRatioWidth",
        @"cropRatioHeight" : @"cropRatioHeight"
    };
}

+ (NSValueTransformer *)mediaTypesJSONTransformer
{
    return [BDXBridgeCustomValueTransformer optionsTransformerWithDictionary:@{
        @"video": @(BDXBridgeMediaTypeVideo),
        @"image": @(BDXBridgeMediaTypeImage),
    }];
}

+ (NSValueTransformer *)sourceTypeJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"album": @(BDXBridgeMediaSourceTypeAlbum),
        @"camera": @(BDXBridgeMediaSourceTypeCamera),
    }];
}

+ (NSValueTransformer *)cameraTypeJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"front": @(BDXBridgeCameraTypeFront),
        @"back": @(BDXBridgeCameraTypeBack),
    }];
}

@end

@implementation BDXBridgeChooseMediaMethodResultTempFileModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"tempFilePath": @"tempFilePath",
        @"size": @"size",
        @"mediaType": @"mediaType",
        @"binaryData": @"binaryData",
    };
}

+ (NSValueTransformer *)mediaTypeJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"video": @(BDXBridgeMediaTypeVideo),
        @"image": @(BDXBridgeMediaTypeImage),
    }];
}

@end

@implementation BDXBridgeChooseMediaMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"tempFiles": @"tempFiles",
    };
}

+ (NSValueTransformer *)tempFilesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:BDXBridgeChooseMediaMethodResultTempFileModel.class];
}

@end
