//
//  DYOpenStorageDefine.h
//  testApp
//
//  Created by gejunchen.ChenJr on 2021/11/11.
//

NS_ASSUME_NONNULL_BEGIN

extern const int32_t kDYOpenLimitedSizeInBytes;

extern NSString *const DYOpen_STORAGE_SIZE_KEY;

extern NSString *const DYOpen_STORAGE_SIZE_JSON_KEY;

extern NSString *const DYOpen_DEFAULT_JSON_KEY;

@interface DYOpenKVItem: NSObject

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) id value;

@end

NS_ASSUME_NONNULL_END
