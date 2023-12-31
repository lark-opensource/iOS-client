// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxError.h"
#import "LynxResourceFetcher.h"
#import "LynxResourceProvider.h"
#import "LynxTextStyle.h"
#import "LynxView.h"

typedef NS_ENUM(NSUInteger, LynxFontSrcType) {
  LynxFontSrcLocal = 0,
  LynxFontSrcUrl,
};

@interface LynxFontSrcItem : NSObject
@property(nonatomic, assign) LynxFontSrcType type;
@property(nonatomic, strong) NSString *src;
@property(nonatomic, strong) NSString *dataFontName;
@property(nonatomic, strong) NSPointerArray *notifierArray;
@end

@interface LynxAliasFontInfo : NSObject
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, strong) NSString *name;
- (bool)isEmpty;
@end

@interface LynxFontFace : NSObject
- (instancetype)initWithFamilyName:(NSString *)familyName andSrc:(NSString *)src;
- (NSUInteger)srcCount;
- (LynxFontSrcItem *)srcAtIndex:(NSUInteger)index;
@end

@protocol LynxFontFaceObserver <NSObject>
@optional
- (void)onFontFaceLoad;

@end
@interface LynxFontFaceContext : NSObject
@property(nonatomic, weak) id<LynxResourceFetcher> resourceFetcher;
@property(nonatomic, weak) id<LynxResourceProvider> resourceProvider;
@property(nonatomic, weak) LynxView *rootView;
@property(nonatomic, weak) NSDictionary *builderRegistedAliasFontMap;
- (void)addFontFace:(LynxFontFace *)fontFace;
- (LynxFontFace *)getFontFaceWithFamilyName:(NSString *)familyName;
@end

@interface LynxFontFaceManager : NSObject
+ (LynxFontFaceManager *)sharedManager;
- (UIFont *)generateFontWithSize:(CGFloat)fontSize
                          weight:(CGFloat)fontWeight
                           style:(LynxFontStyleType)fontStyle
                  fontFamilyName:(NSString *)fontFamilyName
                 fontFaceContext:(LynxFontFaceContext *)fontFaceContext
                fontFaceObserver:(id<LynxFontFaceObserver>)observer;
- (void)registerFont:(UIFont *)font forName:(NSString *)name;
- (void)registerFamilyName:(NSString *)fontFamilyName withAliasName:(NSString *)aliasName;
@end
