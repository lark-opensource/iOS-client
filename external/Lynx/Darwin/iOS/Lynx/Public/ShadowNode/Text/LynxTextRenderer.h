// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxEventTargetSpan.h"
#import "LynxTextLayoutSpec.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxTextAttachmentInfo : NSObject

- (instancetype)initWithSign:(NSInteger)sign andFrame:(CGRect)frame;

@property(nonatomic, readonly) NSInteger sign;
@property(nonatomic, readonly) CGRect frame;
@property(nonatomic, assign) BOOL nativeAttachment;

@end

@interface LynxTextRenderer : NSObject

- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr
                              layoutSpec:(LynxLayoutSpec *)spec;

@property(nonatomic, readonly) NSAttributedString *attrStr;
@property(nonatomic, readonly) LynxLayoutSpec *layoutSpec;

@property(nonatomic, readonly) NSLayoutManager *layoutManager;
@property(nonatomic, readonly) NSTextStorage *textStorage;

@property(nonatomic, readonly) NSArray<LynxEventTargetSpan *> *subSpan;
@property(nonatomic, strong, nullable) UIColor *selectionColor;

@property(nonatomic, strong, nullable) NSArray<LynxTextAttachmentInfo *> *attachments;
@property(nonatomic) CGFloat baseline;

/**
 Returns the computed size of the renderer given the constrained size and other parameters.
 */
- (CGSize)size;
- (CGSize)textsize;
- (CGFloat)maxfontsize;

- (void)drawRect:(CGRect)bounds padding:(UIEdgeInsets)padding border:(UIEdgeInsets)border;
- (void)genSubSpan;

@end

NS_ASSUME_NONNULL_END
