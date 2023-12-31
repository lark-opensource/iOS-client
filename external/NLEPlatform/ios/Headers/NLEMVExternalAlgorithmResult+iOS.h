//
//  NLEMVExternalAlgorithmResult+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/11.
//

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLENativeDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEMVExternalAlgorithmResult_OC : NLENode_OC

/// 原图
@property (nonatomic, strong) NLEResourceNode_OC *photo;

/// hair,background……
@property (nonatomic, strong) NLEResourceNode_OC *mask;

/// mask文件的存储地址
@property (nonatomic, copy) NSString *algorithmName;

/// 资源类型
@property (nonatomic, assign) NLESegmentMVResultInType resultInType;

@end

NS_ASSUME_NONNULL_END
