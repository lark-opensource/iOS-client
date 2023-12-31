//
//  GPNetServiceProtocol.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import "GPRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^GPRequestModelBlock)(GPRequestModel * _Nullable requestModel);
typedef void (^GPNetServiceCompletionBlock)(id _Nullable model, NSError * _Nullable error);

@protocol GPNetServiceProtocol <NSObject>

- (NSString *)defaultDomain;

// 返回指定的模型，若没指定，直接返回json
- (id)uploadWithModel:(GPRequestModelBlock)requestModelBlock
             progress:(NSProgress *_Nullable __autoreleasing *_Nullable)progress
           completion:(GPNetServiceCompletionBlock _Nullable)block;

- (NSString *)currentLanguage;

@end

NS_ASSUME_NONNULL_END
