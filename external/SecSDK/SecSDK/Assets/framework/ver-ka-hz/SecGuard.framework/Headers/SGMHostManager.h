//
//  SGMHostManager.h
//  SecGuard
//
//  Created by jianghaowne on 2019/3/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SGMHostCategory)
{
    SGMHostCategoryInfo, ///< 上报
    SGMHostCategoryVerify, ///< 验证码
    SGMHostCategorySenseless, ///< 无感验证
    SGMHostCategorySelas, ///< 设备指纹
    SGMHostCategoryLog, ///< 日志
};

@interface SGMHostManager : NSObject

@property (atomic) NSDictionary <NSNumber *, NSString *> *hostDic;

+ (instancetype)manager;

/*
 * @param category host类型
 * @param appToken app标识，可能是appid，也可能是appkey
 */

- (NSString *)hostForCategory:(SGMHostCategory)category appToken:(NSString *)appToken;

/*
 * @param category host类型
 * @param appToken app标识，可能是appid，也可能是appkey
 * @param isHybrid YES表示对外
 */
- (NSString *)hostForCategory:(SGMHostCategory)category appToken:(NSString *)appToken isHybrid:(BOOL)isHybrid;

@end

NS_ASSUME_NONNULL_END
