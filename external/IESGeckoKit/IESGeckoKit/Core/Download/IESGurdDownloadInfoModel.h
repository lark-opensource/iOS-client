#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDownloadInfoModel : NSObject

@property (nonatomic, copy) NSString *identity;

@property (nonatomic, copy) NSString *currentDownloadURLString;

@property (nonatomic, copy) NSArray<NSString *> *allDownloadURLStrings;

@property (nonatomic, assign) uint64_t packageSize; // 包大小

@end

NS_ASSUME_NONNULL_END
