//
//  BDXLynxInlineImageShadowNode.h
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import <Lynx/LynxShadowNode.h>
#import "BDXLynxAbstractTextShadowNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxInlineImageShadowNode : BDXLynxAbstractTextShadowNode

@property (nonatomic) NSURL *src;

@end

NS_ASSUME_NONNULL_END
