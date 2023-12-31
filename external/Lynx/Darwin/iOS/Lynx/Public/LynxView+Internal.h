// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxView.h"

@interface LynxView ()

@property(nonatomic, nullable) LynxTemplateRender* templateRender;

- (NSDictionary* _Nullable)getAllJsSource;

@end

@interface LynxViewBuilder ()

- (NSDictionary* _Nonnull)getLynxResourceProviders;

- (NSDictionary* _Nonnull)getBuilderRegistedAliasFontMap;

@end
