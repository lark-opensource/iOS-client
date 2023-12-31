//
//  CJPayHostModel.h
//  Pods
//
//  Created by chenbocheng on 2021/10/27.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayHostModel : JSONModel

@property (nonatomic, copy) NSString *bdHostDomain;
@property (nonatomic, copy) NSArray<NSString *> *h5PathList;//白名单，暂时没用上
@property (nonatomic, copy) NSString *integratedHostDomain;

@end

NS_ASSUME_NONNULL_END
