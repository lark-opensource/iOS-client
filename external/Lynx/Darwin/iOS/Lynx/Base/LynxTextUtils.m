// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxTextUtils.h"
#import <NaturalLanguage/NaturalLanguage.h>

NSString *const ELLIPSIS = @"\u2026";
// Strong direction unicodes to control the direction of ellipsis
NSString *const LTR_MARK = @"\u200E";
NSString *const RTL_MARK = @"\u200F";

@implementation LynxTextUtils

+ (NSTextAlignment)applyNaturalAlignmentAccordingToTextLanguage:
                       (nonnull NSMutableAttributedString *)attrString
                                                       refactor:(BOOL)enableRefactor {
  if (attrString == nil) {
    return NSTextAlignmentNatural;
  }
  NSRange range = NSMakeRange(0, attrString.length);
  if (range.length == 0) {
    return NSTextAlignmentNatural;
  }
  // Fetch the outer paragraph style from the attributed string
  NSMutableParagraphStyle *paraStyle = [[attrString attribute:NSParagraphStyleAttributeName
                                                      atIndex:0
                                        longestEffectiveRange:nil
                                                      inRange:range] mutableCopy];
  if (paraStyle == nil) {
    // If the paragraph style is not set, use the default one.
    paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  }

  NSTextAlignment paraAlignment = paraStyle.alignment;
  NSTextAlignment physicalAlignment = paraAlignment;

  // Only run language detection for first 20 utf-16 codes, that would work for direction detection
  // in most cases.
  const int LANGUAGE_DETECT_MAX_LENGTH = 20;
  // If the paragraph alignment is natural, decide the alignment according to the locale of content.
  if (physicalAlignment == NSTextAlignmentNatural) {
    NSString *text = [attrString string];

    if (text.length) {
      NSString *language = nil;
      // Guess best matched langauge basing on the content.
      if (enableRefactor) {
        if (@available(iOS 12.0, *)) {
          language = [NLLanguageRecognizer dominantLanguageForString:text];
        } else {
          NSLinguisticTagger *tagger =
              [[NSLinguisticTagger alloc] initWithTagSchemes:@[ NSLinguisticTagSchemeLanguage ]
                                                     options:0];
          [tagger setString:text];
          language = [tagger tagAtIndex:0
                                 scheme:NSLinguisticTagSchemeLanguage
                             tokenRange:NULL
                          sentenceRange:NULL];
        }
      } else {
        language = CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage(
            (CFStringRef)text, CFRangeMake(0, MIN([text length], LANGUAGE_DETECT_MAX_LENGTH))));
      }

      if (language) {
        // Get the direction of the guessed locale
        NSLocaleLanguageDirection direction = [NSLocale characterDirectionForLanguage:language];
        physicalAlignment = (direction == NSLocaleLanguageDirectionRightToLeft)
                                ? NSTextAlignmentRight
                                : NSTextAlignmentLeft;
      }
    }
  }
  // If there is a inferred alignment, apply the inferred alignment to the paragraph.
  if (physicalAlignment != paraAlignment) {
    paraStyle.alignment = physicalAlignment;
    [attrString addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
  }
  return physicalAlignment;
}

+ (nonnull NSString *)getEllpsisStringAccordingToWritingDirection:(NSWritingDirection)direction {
  if (direction == NSWritingDirectionNatural) {
    return ELLIPSIS;
  }
  return [NSString
      stringWithFormat:@"%@%@", (direction == NSWritingDirectionLeftToRight ? LTR_MARK : RTL_MARK),
                       ELLIPSIS];
}

@end
