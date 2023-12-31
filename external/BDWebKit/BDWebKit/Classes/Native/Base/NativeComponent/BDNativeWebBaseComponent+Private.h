//
//  BDNativeWebBaseComponent+Private.h
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/9/9.
//

#import "BDNativeWebBaseComponent.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDNativeWebBaseComponent()

@property (nonatomic, strong) NSString *iFrameID;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSNumber *tagId;
@property (nonatomic, strong) NSArray<NSNumber *> *radiusNums;

@end

@interface BDNativeWebBaseComponent (Private)

- (void)containerFrameChanged:(BDNativeWebContainerObject *)containerObject;

- (void)baseInsertInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params;

- (void)baseUpdateInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params;

- (void)baseDeleteInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
