//
//  GPServerHandleResourceModel.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GPServerHandleErrorCode) {
    GPServerHandleErrorCodeNone = 0,
    // 网络错误
    GPServerHandleErrorCodeNetworkFailed,
    // 传入的数据模型不对
    GPServerHandleErrorCodeModelUnmatched,
    
    // 以下为生成GPMaterialOutputModel时的错误
    GPServerHandleErrorCodeCreateFileFailed,
    GPServerHandleErrorCodeWriteFileFailed,
    GPServerHandleErrorCodeEmptyContent,
    GPServerHandleErrorCodeImageUnavailable,
};

@interface GPServerHandleResourceModel : NSObject

@end

@interface GPServerHandlePicAfrModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *algorithm;
@property (nonatomic, assign) CGFloat maskArea;
@property (nonatomic, copy) NSString *pic;
@property (nonatomic, assign) CGFloat maskRatio;
@property (nonatomic, copy) NSString *picConf;

@end

@interface GPServerHandlePicData : MTLModel <MTLJSONSerializing>
//
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSArray<GPServerHandlePicAfrModel*> *models;

@end

@interface GPServerHandlePicResponse : MTLModel <MTLJSONSerializing>
//
@property (nonatomic, strong) GPServerHandlePicData *data;

@end

@interface GPServerHandleVideoModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *algorithm;
@property (nonatomic, copy) NSString *videoConf;
@property (nonatomic, copy) NSString *content;

@end

@interface GPServerHandleVideoData : MTLModel <MTLJSONSerializing>
//
@property (nonatomic, copy) NSString *key;
@property (nonatomic, strong) GPServerHandleVideoModel *model;

@end

@interface GPServerHandleVideoResponse : MTLModel <MTLJSONSerializing>
//
@property (nonatomic, strong) GPServerHandleVideoData *data;

@end

NS_ASSUME_NONNULL_END
