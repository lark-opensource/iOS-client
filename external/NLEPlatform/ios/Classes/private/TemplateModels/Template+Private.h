//
//  Template+Private.h
//  TemplateConsumer
//
//  Created by Lemonior on 2021/9/23.
//

#ifndef Template_Private_h
#define Template_Private_h

#import "TemplateConfig.h"
#import "TemplateConfig+iOS.h"
#import "TemplateInfo.h"
#import "TemplateInfo+iOS.h"
#import "NLEMappingNode.h"
#import "NLEMappingNode+iOS.h"

@interface TemplateConfig_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::TemplateConfig> cppModel;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::TemplateConfig>)cppModel;

@end

@interface TemplateInfo_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::TemplateInfo> cppModel;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::TemplateInfo>)cppModel;

@end

@interface NLEMappingNode_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEMappingNode> cppMappingNode;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEMappingNode>)cppNode;

@end

#endif /* Template_Private_h */
