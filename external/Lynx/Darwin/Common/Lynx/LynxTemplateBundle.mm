//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxTemplateBundle.h"
#import "LynxTemplateBundle+Converter.h"
#import "shell/ios/native_facade_darwin.h"
#include "tasm/binary_decoder/lynx_binary_reader.h"
#include "tasm/react/ios/lepus_value_converter.h"

@implementation LynxTemplateBundle {
  std::shared_ptr<lynx::tasm::LynxTemplateBundle> template_bundle_;
  NSString* error;
  NSDictionary* extraInfo;
}

- (instancetype)initWithTemplate:(NSData*)tem {
  if (self = [super init]) {
    auto source = ConvertNSBinary(tem);
    auto input_stream = std::make_unique<lynx::lepus::ByteArrayInputStream>(std::move(source));
    lynx::tasm::LynxBinaryReader decoder(std::move(input_stream));
    decoder.SetIsCard(true);
    if (decoder.Decode()) {
      // decode success.
      template_bundle_ =
          std::make_shared<lynx::tasm::LynxTemplateBundle>(decoder.GetTemplateBundle());
    } else {
      // decode failed.
      error = [NSString stringWithUTF8String:decoder.error_message_.c_str()];
    }
  }
  return self;
}

- (NSString*)errorMsg {
  return error;
}

- (NSDictionary*)extraInfo {
  if ([self errorMsg]) {
    NSLog(@"cannot get extraInfo through a invalid TemplateBundle.");
    return @{};
  }
  if (!extraInfo) {
    lynx::lepus::Value value = template_bundle_->GetExtraInfo();
    extraInfo = lynx::tasm::convertLepusValueToNSObject(value);
  }
  return extraInfo;
}

std::shared_ptr<lynx::tasm::LynxTemplateBundle> LynxGetRawTemplateBundle(
    LynxTemplateBundle* bundle) {
  if ([bundle errorMsg]) {
    return nullptr;
  }
  return bundle->template_bundle_;
}

@end
