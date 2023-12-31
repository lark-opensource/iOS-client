//
//  ACCNewYearWishEditModel.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/1.
//

#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>

@class AWEAssetModel;

@interface ACCNewYearWishEditModel : MTLModel<MTLJSONSerializing>

// 文字内容
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, assign) BOOL officialText;
// 背景模板
@property (nonatomic, copy, nullable) NSString *effectId;
// 头像数据
@property (nonatomic, copy, nullable) NSString *avatarPath;// 本地路径
@property (nonatomic, copy, nullable) NSString *originAvatarPath;// 原图本地路径
@property (nonatomic, copy, nullable) NSString *avatarURI;// 资源URI，送审用
// 自选图片
@property (nonatomic, copy, nullable) NSArray<NSString *> *images;
@property (nonatomic, copy, nullable) NSArray<AWEAssetModel *> *imageModels;

@end
