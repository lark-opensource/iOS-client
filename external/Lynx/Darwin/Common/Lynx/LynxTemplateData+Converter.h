// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXTEMPLATEDATA_CONVERTER_H_
#define DARWIN_COMMON_LYNX_LYNXTEMPLATEDATA_CONVERTER_H_

#include <Lynx/LynxTemplateData.h>

#include <memory>

#include "lepus/value.h"
#include "tasm/template_data.h"

lynx::lepus::Value LynxConvertToLepusValue(id data);

@class LynxTemplateData;
lynx::lepus::Value *LynxGetLepusValueFromTemplateData(LynxTemplateData *data);

std::shared_ptr<lynx::tasm::TemplateData> ConvertLynxTemplateDataToTemplateData(
    LynxTemplateData *data);

@interface LynxTemplateData ()

@property(readonly) NSString *processorName;

- (LynxTemplateData *)deepClone;

@end

#endif  // DARWIN_COMMON_LYNX_LYNXTEMPLATEDATA_CONVERTER_H_
