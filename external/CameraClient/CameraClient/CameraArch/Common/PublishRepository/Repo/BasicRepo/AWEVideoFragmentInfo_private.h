//
//  AWEVideoFragmentInfo_private.h
//  CameraClient-Pods-Aweme
//
//  Created by 马超 on 2021/4/9.
//

#import "AWEVideoFragmentInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoFragmentInfo()

/*
 老版本 challenge 兼容
 新版本支持多 challenge，外部统一使用 challengeInfos
 Mantle 是根据对象属性列表来给 -initWithDictionary:error: 方法传入 dictionaryValue
 如果没有这2属性，dictionaryValue 中会丢失老版本的 'challengeID', 'challengeName' key
 */
@property (nonatomic, copy) NSString *challengeID;
@property (nonatomic, copy) NSString *challengeName;

@property (nonatomic, assign, readwrite) UIEdgeInsets frameInset;

@end

NS_ASSUME_NONNULL_END
