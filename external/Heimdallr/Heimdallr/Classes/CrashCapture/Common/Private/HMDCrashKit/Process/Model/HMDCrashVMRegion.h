//
//  HMDCrassAddressVMRegion.h
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashModel.h"
#import <mach/vm_region.h>
#import "HMDCrashBinaryImage.h"
NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashVMRegion : HMDCrashModel

@property(nonatomic,assign) vm_prot_t protection;
@property(nonatomic,assign) vm_prot_t max_protection;
@property(nonatomic,assign) unsigned int user_tag;
@property(nonatomic,assign) uint64_t resident_size;
@property(nonatomic,assign) uint64_t swapped_size;
@property(nonatomic,assign) uint64_t dirty_size;
@property(nonatomic,assign) unsigned char share_mode;
@property(nonatomic,assign) unsigned char external_pager;
@property(nonatomic,copy) NSString *file;

@property(nonatomic,assign) vm_address_t base;
@property(nonatomic,assign) vm_size_t size;

@property(nonatomic,copy) NSString *protectionString;
@property(nonatomic,copy) NSString *userTagString;
@property(nonatomic,copy) NSString *shareModeString;

@property(nonatomic,strong) HMDCrashSegment *segment;
@property(nonatomic,strong) HMDCrashBinaryImage *image;

- (NSDictionary *)postDict;

@end

NS_ASSUME_NONNULL_END
