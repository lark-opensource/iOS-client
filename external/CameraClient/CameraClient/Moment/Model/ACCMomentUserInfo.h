//
//  ACCMomentUserInfo.h
//  Pods
//
//  Created by Pinka on 2020/5/28.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentUserInfo : MTLModel

// 用户常驻地：具体城市名，"%s_%s_%s", 国家-省-城市，UTF-8编码
@property (nonatomic, copy) NSString *place;
@property (nonatomic, assign) float age;
@property (nonatomic, assign) float boyProb;

@end

NS_ASSUME_NONNULL_END
