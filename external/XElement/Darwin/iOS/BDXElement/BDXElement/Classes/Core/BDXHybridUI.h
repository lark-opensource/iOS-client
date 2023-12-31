//
//  BDXHybridUI.h
//  BDXElement
//
//  Created by li keliang on 2020/11/23.
//

#import <Foundation/Foundation.h>

#if !defined BDX_DYNAMIC
#if __has_attribute(objc_dynamic)
#define BDX_DYNAMIC __attribute__((objc_dynamic))
#else
#define BDX_DYNAMIC
#endif
#endif

#ifndef CONCAT
#define CONCAT2(A, B) A##B
#define CONCAT(A, B) CONCAT2(A, B)
#endif

#define BDX_PROP_SETTER(name, type) \
-(void)CONCAT(bdx_, name):(type)value requestReset:(bool)requestReset BDX_DYNAMIC

@protocol BDXHybridUIEventDispatcher <NSObject>

- (void)sendCustomEvent:(NSString * _Nonnull)event params:(NSDictionary * _Nullable)params;

@end

@protocol BDXHybridUIContext <NSObject>

@optional
- (nullable id)bdx_context;

- (CGRect)bdx_frame;

- (nullable NSURL *)bdx_containerURL;

@end

@interface BDXHybridUI<__covariant V : UIView*> : NSObject

@property (nonatomic, weak, nullable) id<BDXHybridUIEventDispatcher> eventDispatcher;

@property (nonatomic, weak, nullable) id<BDXHybridUIContext> context;

+ (nonnull NSString *)tagName; // should overwrite

- (nonnull V)createView; // should overwrite

- (nonnull V)view;

- (void)layoutDidFinished; // should overwrite

- (void)updateAttribute:(NSString * _Nonnull)attribute value:(__nullable id)value requestReset:(BOOL)requestReset;

@end
