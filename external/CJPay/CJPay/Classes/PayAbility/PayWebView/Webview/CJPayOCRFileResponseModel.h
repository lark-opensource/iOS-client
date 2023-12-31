//
//  CJPayOCRFileResponseModel.h
//  Pods
//
//  Created by bytedance on 2021/11/3.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOCRFileResponseModel : JSONModel

@property (nonatomic, copy) NSString *mediaType;
@property (nonatomic, copy) NSString *size;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *metaFile;
@property (nonatomic, copy) NSString *metaFilePrefix;

@end

NS_ASSUME_NONNULL_END
