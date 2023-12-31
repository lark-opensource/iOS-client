//
//  HMDCrashAddressObjectInfo.h
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashAddressObjectInfo : HMDCrashModel

@property(nonatomic,assign) CFTypeID cf_typeID;
@property(nonatomic,copy) NSString *className;
@property(nonatomic,assign) BOOL isAligned;
@property(nonatomic,assign) BOOL is_tagpointer;
@property(nonatomic,assign) uintptr_t isa_value;
@property(nonatomic,assign) BOOL isClass;
@property(nonatomic,assign) BOOL isObject;
@property(nonatomic,copy) NSString *content;
@end

NS_ASSUME_NONNULL_END
