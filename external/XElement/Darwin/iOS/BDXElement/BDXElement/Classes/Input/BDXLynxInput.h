//
//  BDXLynxInput.h
//  Pods
//
//  Created by shenweizheng on 2020/5/11.
//

#import <Lynx/LynxUI.h>
#import "BDXLynxTextView.h"
#import "BDXLynxKeyListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxInput : LynxUI<UITextField *>

@property (nonatomic, assign, readwrite) NSInteger maxLength;
@property (nonatomic, assign, readwrite) BOOL readonly;
@property (nonatomic, assign, readwrite) BOOL mIsChangeFromLynx;
@property (nonatomic, readwrite) NSString* mFilterPattern;
@property (nonatomic, readwrite) NSString* mAdjustMode;
@property (nonatomic, assign, readwrite) BOOL mAutoFit;
@property (nonatomic, assign, readwrite) CGFloat mBottomInset;
@property (nonatomic, assign, readwrite) CGFloat mKeyboardHeight;
@property (nonatomic, assign, readwrite) NSInteger mInputType;
@property (nonatomic, readwrite) id<BDXLynxKeyListener> mKeyListener;
@property (nonatomic, assign, readwrite) CGFloat mLetterSpacing;
@property (nonatomic, assign, readwrite) CGFloat mFontSize;
@property (nonatomic, assign, readwrite) CGFloat mFontWeight;
@property (nonatomic, assign, readwrite) CGFloat mPlaceholderFontSize;
@property (nonatomic, assign, readwrite) CGFloat mPlaceholderFontWeight;
@property (nonatomic, assign, readwrite) BOOL mPlaceholderUseCustomFontSize;
@property (nonatomic, assign, readwrite) BOOL mPlaceholderUseCustomFontWeight;
@property (nonatomic, assign, readonly) CGFloat textHeight;
@property (nonatomic, assign, readonly) BOOL mCompatNumberType;
@property (nonatomic, assign, readonly) BOOL mSendComposingInputEvent;
@property (nonatomic, readonly) NSString* mFontFamilyName;
@property (nonatomic, readonly) NSString* mPlaceholderFontFamilyName;
@property (nonatomic, assign, readonly) BOOL mPlaceholderUseCustomFontFamily;
@property (nonatomic, assign, readonly) BOOL fontStyleChanged;
@property (nonatomic, assign, readonly) BOOL placeholderFontStyleChanged;
@property (nonatomic, readonly) NSInteger sourceLength;
@property (nonatomic, readwrite) UIView *mInputAccessoryView;

@end

NS_ASSUME_NONNULL_END
