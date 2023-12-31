// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_RICHTEXT_ANDROID_RICH_TEXT_PARSER_ANDROID_H_
#define LYNX_RICHTEXT_ANDROID_RICH_TEXT_PARSER_ANDROID_H_

#include <jni.h>

namespace lynx {

class RichTextParserAndroid final {
 public:
  RichTextParserAndroid() = delete;
  ~RichTextParserAndroid() = delete;

  static void RegisterJNI(JNIEnv* env);
};

}  // namespace lynx

#endif  // LYNX_RICHTEXT_ANDROID_RICH_TEXT_PARSER_ANDROID_H_
