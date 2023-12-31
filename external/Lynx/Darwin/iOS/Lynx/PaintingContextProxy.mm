//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "PaintingContextProxy.h"

@implementation PaintingContextProxy {
  // not owned, LynxShell released after platform, ensure life cycle
  lynx::tasm::PaintingContextDarwin* painting_context_;
}

- (instancetype)initWithPaintingContext:(lynx::tasm::PaintingContextDarwin*)paintingContext {
  if (self = [super init]) {
    painting_context_ = paintingContext;
  }
  return self;
}

- (void)updateExtraData:(NSInteger)sign value:(id)value {
  // this method can be removed
}

- (void)updateLayout:(NSInteger)sign
          layoutLeft:(CGFloat)left
                 top:(CGFloat)top
               width:(CGFloat)width
              height:(CGFloat)height {
  painting_context_->UpdateLayout((int)sign, left, top, width, height, nullptr, nullptr, nullptr,
                                  nullptr, nullptr, 0);
}

- (void)finishLayoutOperation {
  painting_context_->LayoutDidFinish();
  painting_context_->Flush();
}

- (void)setEnableFlush:(BOOL)enableFlush {
  painting_context_->SetEnableFlush(enableFlush);
}

- (void)forceFlush {
  painting_context_->ForceFlush();
}

- (BOOL)isLayoutFinish {
  return painting_context_->IsLayoutFinish();
}

- (void)resetLayoutStatus {
  painting_context_->ResetLayoutStatus();
}

@end
