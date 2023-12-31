//
//  LolaDrawContext.h
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/27.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LynxUI;

NS_ASSUME_NONNULL_BEGIN
typedef void (^LolaImageLoadCompletionBlock)(UIImage* _Nullable image, NSError* _Nullable error,
                                             NSURL* _Nullable imageURL);


typedef NS_ENUM(NSInteger, LolaTextBaseLine) {
  LolaTextBaseLine_Normal = 0,
  LolaTextBaseLine_TOP,
  LolaTextBaseLine_BOTTOM,
  LolaTextBaseLine_MIDDLE,
  LolaTextBaseLine_HANGDING
};

@interface LolaDrawContext : NSObject

@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;

@property (nonatomic, assign) CGLineCap lineCap;
@property (nonatomic, assign) CGLineJoin lineJoin;

//private var textAlign = Paint.Align.LEFT
@property (nonatomic, assign) CGFloat textAlign;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) LolaTextBaseLine baseLine;

//  private var strokeWidth = DEFAULT_LINE_WIDTH
@property (nonatomic, assign) CGFloat lineWidth;

//TODO:需要重置吗？
@property (nonatomic, assign) CGBlendMode blendMode;

//shadow
@property (nonatomic, assign) CGFloat shadowX;
@property (nonatomic, assign) CGFloat shadowY;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, strong) UIColor *shadowColor;

@property (nonatomic, assign) CGFloat miterLimit;
@property (nonatomic, assign) CGFloat globalAlpha;
@property (nonatomic, assign) BOOL antiAlias;
@property (nonatomic, strong) UIBezierPath *lastPath;


- (instancetype)initWithTargetUI:(LynxUI *)view;

- (void)addNewPath:(UIBezierPath *)path;
- (UIBezierPath *)currentPath;

- (void)invidate;

//todo:单独抽象protocol
- (void)loadImageWithURL:(nonnull NSURL *)url size:(CGSize)targetSize contextInfo:(nullable NSDictionary *)contextInfo completion:(nonnull LolaImageLoadCompletionBlock)completionBlock;

//
@end

NS_ASSUME_NONNULL_END
