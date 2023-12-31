// Copyright 2021 The Lynx Authors. All rights reserved.

@interface CustomizedMessage : NSObject

@property(nonatomic, readwrite) NSString *type;
@property(nonatomic, readwrite) NSString *data;
@property(nonatomic, assign) int mark;

@end
