//
//  DVEEffectValue.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEResourceCategoryModelProtocol.h"
#import <DVEFoundationKit/NSString+DVE.h>
#import <DVEFoundationKit/DVEImageMacro.h>

typedef NS_ENUM(NSUInteger, DVEEffectValueState) {
    DVEEffectValueStateNone          = 0,
    DVEEffectValueStateInUse        ,
    DVEEffectValueStateShuntDown          ,
};

NS_ASSUME_NONNULL_BEGIN

@interface DVEEffectValue : NSObject<NSCopying,NSMutableCopying,DVEResourceModelProtocol>
@property (nonatomic, assign) DVEEffectValueState valueState;
@property (nonatomic, assign) float indesty;
@property (nonatomic, strong) id<DVEResourceModelProtocol> injectModel;

- (instancetype)initWithInjectModel:(id<DVEResourceModelProtocol>)model;

@end

NS_ASSUME_NONNULL_END
