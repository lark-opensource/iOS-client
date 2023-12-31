//
//  TemplateInfo+iOS.h
//  TemplateConsumer
//
//  Created by Lemonior on 2021/9/23.
//

#import "NLENode+iOS.h"
#import "TemplateConfig+iOS.h"
#import "NLEMappingNode+iOS.h"
#import "NLEVideoFrameModel+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface TemplateInfo_OC : NLENode_OC

@property (nonatomic, copy) NSString *templateId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, strong) TemplateConfig_OC *config;

- (NSString *)store;
+ (TemplateInfo_OC *)restore:(NSString *)str;

@property (nonatomic) NLEResourceNode_OC *coverRes;
@property (nonatomic, strong) NLEVideoFrameModel_OC *coverModel;


- (void)addMutableItem:(NLEMappingNode_OC *)mappingNode;
- (void)clearMutableItem;
- (NSArray<NLEMappingNode_OC *> *)allMutableItems;


@end

NS_ASSUME_NONNULL_END
