//
//  CJPayPrefetchConfig.h
//  CJPay
//
//  Created by wangxinhua on 2020/5/13.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPrefetchRequestModel : JSONModel

@property (nonatomic, copy) NSString *api;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *dataType;
@property (nonatomic, copy) NSDictionary *data;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSDictionary *dataFields;
@property (nonatomic, copy) NSArray<NSString *> *hosts;
@property (nonatomic, copy) NSArray<NSString *> *dataToJSONKeyPaths;

@end

@protocol CJPayPrefetchRequestModel;
@interface CJPayPrefetchConfig : JSONModel

@property (nonatomic, copy) NSArray<CJPayPrefetchRequestModel> *prefetchDatas;

- (nullable CJPayPrefetchRequestModel *)getRequestModelByUrl:(NSString *)Url;

@end

NS_ASSUME_NONNULL_END
