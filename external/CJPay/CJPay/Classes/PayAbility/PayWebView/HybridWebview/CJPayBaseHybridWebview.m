//
//  CJPayBaseHybridWebview.m
//  cjpaysandbox
//
//  Created by ByteDance on 2023/5/6.
//

#import "CJPayBaseHybridWebview.h"
#import "CJPayHybridPlugin.h"
#import "CJPayHybridHelper.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonUtil.h"

@interface CJPayBaseHybridWebview()

@property (nonatomic, strong) UIView *hybridView;
@property (nonatomic, copy) NSString *scheme;
@property (nonatomic, weak) id delegate;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, weak, readwrite) WKWebView *webview;

@end

@implementation CJPayBaseHybridWebview

- (instancetype)initWithScheme:(NSString *)scheme delegate:(id)delagate initialData:(NSDictionary *)params {
    self = [super init];
    if (self) {
        _scheme = scheme;
        _delegate = delagate;
        _params = Check_ValidDictionary(params) ? [params copy] : @{};
        [self p_init];
    }
    return self;
}

- (void)p_init {
    NSDictionary *queryItems = [self.scheme cj_urlQueryParams];
    NSURLComponents *components = [NSURLComponents componentsWithString:self.scheme];
    __block NSMutableDictionary *appendParams = [NSMutableDictionary new];
    
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //存在这个参数，字典取出来的值判断才有意义
        if ([obj.name isEqualToString:@"bounce_enable"] && ![queryItems cj_boolValueForKey:@"bounce_enable"]) {
            [appendParams cj_setObject:@"1" forKey:@"disable_bounces"];//这个需要单独设置
        }
    }];
    
    NSString *resLoader = [queryItems cj_stringValueForKey:@"res_loader"];
    
    if (Check_ValidString(resLoader) && [resLoader isEqualToString:@"forest"]) {
        [appendParams cj_setObject:@"1" forKey:@"use_forest"];
        [appendParams cj_setObject:@"forest" forKey:@"loader_name"];
    }
//    [appendParams cj_setObject:@"1" forKey:@"need_sec_link"];//默认开启
    
    
    self.scheme = [CJPayCommonUtil appendParamsToUrl:self.scheme params:appendParams];
    _hybridView = [CJPayHybridHelper createHybridView:self.scheme wkDelegate:self.delegate initialData:self.params];
    
    if (!_hybridView) {//做个兜底，以防万一没有接入hybrid模块
        return;
    }
    
    _webview = [CJPayHybridHelper getRawWebview:self.hybridView];
    
    [self addSubview:self.hybridView];
    
    CJPayMasMaker(self.hybridView, {
        make.edges.equalTo(self);
    });
}

- (void)sendEvent:(NSString *)event params:(NSDictionary *)data {
    [CJPayHybridHelper sendEvent:event params:data container:self.hybridView];
}

- (NSString *)containerID {
    if (!Check_ValidString(_containerID)) {
        _containerID = CJString([CJPayHybridHelper getContainerID:self.hybridView]);
    }
    return CJString(_containerID);
}
@end
