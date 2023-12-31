//
//  NLENode_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/20.
//

#import <NLEPlatform/NLENode+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLENode_OC (DVE)

/// 实际返回的就是NLENode 的 name 属性值
@property (nonatomic, copy, readonly) NSString *dve_nodeId;

- (void)dve_regenerateNodeId;

@end

NS_ASSUME_NONNULL_END
