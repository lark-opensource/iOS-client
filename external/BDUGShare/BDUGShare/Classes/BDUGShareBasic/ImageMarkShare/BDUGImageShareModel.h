//
//  BDUGImageShareModel.h
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>
#import "BDUGImageShare.h"
#import "BDUGTokenShareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDUGImageShareContentModel : NSObject

@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) BDUGImageShareInfo *originShareInfo;

@end

@interface BDUGImageShareAnalysisResultModel : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *resultInfo;

@property (nonatomic, strong, nullable) BDUGTokenShareAnalysisResultModel *tokenInfo;

+ (instancetype)resultModelWithResultInfo:(NSString * _Nullable)resultInfo;

@end

NS_ASSUME_NONNULL_END
