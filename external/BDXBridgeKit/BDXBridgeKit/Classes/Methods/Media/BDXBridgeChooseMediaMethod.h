//
//  BDXBridgeChooseMediaMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeChooseMediaMethod : BDXBridgeMethod

@end

@interface BDXBridgeChooseMediaMethodParamModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeMediaType        mediaTypes;
@property (nonatomic, assign) BDXBridgeMediaSourceType  sourceType;
@property (nonatomic, assign) BDXBridgeCameraType       cameraType;

@property (nonatomic, assign) BOOL compressImage;
@property (nonatomic, assign) BOOL saveToPhotoAlbum;
@property (nonatomic, assign) BOOL needBinaryData;
@property (nonatomic, strong) NSNumber *compressWidth;
@property (nonatomic, strong) NSNumber *compressHeight;
@property (nonatomic, strong) NSNumber *maxCount;

@property (nonatomic, assign) BOOL isNeedCut;
@property (nonatomic, strong) NSNumber *cropRatioWidth;
@property (nonatomic, strong) NSNumber *cropRatioHeight;

@end

@interface BDXBridgeChooseMediaMethodResultTempFileModel : BDXBridgeModel

@property (nonatomic,   copy) NSString  *tempFilePath;
@property (nonatomic, strong) NSNumber  *size;
@property (nonatomic,   copy) NSArray   *binaryData;

@property (nonatomic, assign) BDXBridgeMediaType mediaType;

@end

@interface BDXBridgeChooseMediaMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSArray<BDXBridgeChooseMediaMethodResultTempFileModel *> *tempFiles;

@end

NS_ASSUME_NONNULL_END
