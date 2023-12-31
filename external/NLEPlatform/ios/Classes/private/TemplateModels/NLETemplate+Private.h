//
//  NLETemplate+Private.h
//  TemplateConsumer
//
//  Created by Charles on 2021/9/5.
//

#ifndef NLETemplate_Private_h
#define NLETemplate_Private_h

#import "NLETemplateModel.h"
#import "NLETemplateModel+iOS.h"
#import "NLEContextProcessor+iOS.h"
#import "NLETemplateEditor+iOS.h"
#import "NLETemplateEditor.h"

@interface NLETemplateModel_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETemplateModel> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETemplateModel>)cppModel;

@end

@interface NLETemplateEditor_OC ()

@property (nonatomic, strong) NLETemplateModel_OC *model;

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETemplateEditor> cppEditor;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETemplateEditor>)cppEditor;

@end

#endif /* NLETemplate_Private_h */
