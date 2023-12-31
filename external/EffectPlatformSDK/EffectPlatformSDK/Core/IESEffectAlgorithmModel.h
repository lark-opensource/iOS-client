//
//  IESEffectAlgorithmModel.h
//  AFNetworking
//
//  Created by nanxiang liu on 2019/1/27.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface IESEffectAlgorithmModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSArray<NSString *> *fileDownloadURLs;
@property (nonatomic, copy) NSString *modelMD5;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, assign) NSInteger sizeType; // 代表分级策略中的模型大小。

@end

