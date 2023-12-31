//
//  CJPayForceHttpsModel.h
//  Pods
//
//  Created by 尚怀军 on 2021/2/24.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayForceHttpsModel : JSONModel

@property (nonatomic, assign) BOOL forceHttpsEnable;
@property (nonatomic, copy) NSArray<NSString *> *allowHttpList;

@end

NS_ASSUME_NONNULL_END
