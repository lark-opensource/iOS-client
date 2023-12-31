//
//  BDXLynxTextView.h
//  Pods
//
//  Created by shenweizheng on 2020/5/11.
//

#import <Lynx/LynxFontFaceManager.h>

#ifndef BDXLynxTextView_h
#define BDXLynxTextView_h

@interface BDXLynxTextView : UITextView

@property (nonatomic, strong) NSString  *placeHolder;
@property (nonatomic, strong) UIColor   *placeHolderColor;
@property (nonatomic, strong) UIFont    *placeHolderFont;
@property (nonatomic, assign) UIEdgeInsets placeHolderEdgeInsets;

@property (nonatomic, weak) UITextView *placeHolderTextView;
@property (nonatomic, assign, readwrite) CGFloat mPlaceHolderFontSize;
@property (nonatomic, assign, readwrite) CGFloat mPlaceHolderFontWeight;
@property (nonatomic, assign, readwrite) BOOL isCustomPlaceHolderFontSize;
@property (nonatomic, assign, readwrite) BOOL isCustomPlaceHolderFontWeight;
@property (nonatomic, assign, readwrite) NSTextAlignment mTextAlignment;
@property (nonatomic, assign, readwrite) BOOL mEnableRichText;
@property (nonatomic, strong, readwrite) NSString* mPlaceholderFontFamilyName;
@property (nonatomic, assign, readwrite) BOOL isCustomPlaceHolderFontFamily;
@property (nonatomic, weak) LynxFontFaceContext *fontFaceContext;
@property (atomic, readonly) BOOL waitingDictationRecognition;

- (void)refreshPlaceHolderFont;
- (void)showOrHidePlaceHolder;
- (void)syncPlaceHolderTextAligment;
- (void)syncPlaceHolderDirection:(NSInteger) directionType;
- (void)syncPlaceHolderLetterSpacing:(CGFloat)letterSpacing;
- (NSString *)getRawText;
- (NSString *)getRawTextInAttributedString:(NSAttributedString *)attributedString;

@end

#endif /* IESLiveUITextView_h */
