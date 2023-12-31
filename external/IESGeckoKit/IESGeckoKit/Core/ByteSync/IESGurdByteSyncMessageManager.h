//
//  IESGurdByteSyncMessageManager.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESGurdByteSyncBusinessType) {
    IESGurdByteSyncBusinessTypeRelease,
    IESGurdByteSyncBusinessTypeBOE
};

typedef NSString * _Nullable(^IESGurdByteSyncCustomParamGetValueBlock)(void);

@interface IESGurdByteSyncMessageManager : NSObject

+ (int32_t)businessIdWithType:(IESGurdByteSyncBusinessType)type;

+ (void)registerCustomParamKey:(NSString *)key
                 getValueBlock:(IESGurdByteSyncCustomParamGetValueBlock)getValueBlock
                  forAccessKey:(NSString *)accessKey;

+ (void)handleMessageDictionary:(NSDictionary *)messageDictionary;

@end

NS_ASSUME_NONNULL_END
