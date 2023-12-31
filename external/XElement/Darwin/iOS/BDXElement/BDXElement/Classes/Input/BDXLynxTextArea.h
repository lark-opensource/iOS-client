//
//  BDXLynxTextArea.h
//  AWEABTest
//
//  Created by annidy on 2020/5/21.
//

#import "BDXLynxInput.h"
#import <Lynx/LynxShadowNode.h>
#import "BDXLynxInputEmojiFormater.h"

#import "BDXLynxTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxTextArea : LynxUI<BDXLynxTextView*>

@property (nonatomic, assign, readwrite) NSInteger maxLength;
@property (nonatomic, assign, readwrite) BOOL readonly;
@property (nonatomic, assign, readonly) BOOL multiline;
@property (nonatomic, assign, readonly) CGFloat textHeight;
@property (nonatomic, readwrite) NSString* adjustMode;
@property (nonatomic, assign, readwrite) BOOL mIsChangeFromLynx;
@property (nonatomic, readwrite) NSString* mFilterPattern;
@property (nonatomic, readwrite) NSString* mAdjustMode;
@property (nonatomic, assign, readwrite) BOOL mAutoFit;
@property (nonatomic, assign, readwrite) CGFloat mBottomInset;
@property (nonatomic, assign, readwrite) CGFloat mKeyboardHeight;
@property (nonatomic, assign, readwrite) BOOL autoHeightInputNeedSmartScroll;
@property (nonatomic, copy, readwrite, nullable) NSDictionary* currentUserInfo;
@property (nonatomic, assign, readwrite) CGFloat mLetterSpacing;
@property (nonatomic, assign, readwrite) CGFloat mFontSize;
@property (nonatomic, assign, readwrite) CGFloat mFontWeight;
@property (nonatomic, assign, readonly) BOOL mEnterShouldConfirm;
@property (nonatomic, assign, readonly) CGFloat mWidth;
@property (nonatomic, assign, readonly) CGFloat mHeight;
@property (nonatomic, strong, nullable) id<BDXLynxInputEmojiFormater> richTextFormater;
@property (nonatomic, assign, readonly) BOOL mSendComposingInputEvent;
@property (nonatomic, readonly) NSString* mFontFamilyName;
@property (nonatomic, assign, readonly) BOOL fontStyleChanged;
@property (nonatomic, assign, readonly) BOOL placeholderFontStyleChanged;
@property (nonatomic, readwrite) UIView *mInputAccessoryView;
@property (nonatomic, assign, readonly) BOOL iosAutoHeightNewer;
@property (nonatomic, assign, readonly) NSInteger maxLines;
@property (nonatomic, assign, readonly) NSInteger sourceLength;
@property (nonatomic, assign, readonly) BOOL iosMaxLinesNewer;

@end

NS_ASSUME_NONNULL_END
