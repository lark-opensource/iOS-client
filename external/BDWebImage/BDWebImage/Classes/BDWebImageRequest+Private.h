//
//  BDWebImageRequest+Private.h
//  BDWebImage
//
//  Created by 陈奕 on 2020/5/24.
//

#import "BDWebImageRequest.h"
#import "BDImageRequestKey.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDWebImageRequest (Private)

@property (nonatomic, strong) BDImageRequestKey *originalKey;/// 初始化并附带 key 的原信息，可生成 memoryKey、sourceKey 等

- (void)setupKeyAndTransformer:(BDBaseTransformer *)transformer;

@end

NS_ASSUME_NONNULL_END
