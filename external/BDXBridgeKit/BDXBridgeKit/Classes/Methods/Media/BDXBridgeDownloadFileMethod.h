//
//  BDXBridgeDownloadFileMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeDownloadFileMethod : BDXBridgeMethod

@end

@interface BDXBridgeDownloadFileMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSString *extension;

@end

@interface BDXBridgeDownloadFileMethodResultModel : BDXBridgeModel

@property (nonatomic, strong) NSNumber *httpCode;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, copy) NSString *filePath;

@end

NS_ASSUME_NONNULL_END
