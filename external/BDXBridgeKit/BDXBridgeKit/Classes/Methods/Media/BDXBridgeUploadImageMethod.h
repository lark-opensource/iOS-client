//
//  BDXBridgeUploadImageMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeUploadImageMethod : BDXBridgeMethod

@end

@interface BDXBridgeUploadImageMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *filePath;

@end

@interface BDXBridgeUploadImageMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSDictionary *response;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *uri;

@end

NS_ASSUME_NONNULL_END
