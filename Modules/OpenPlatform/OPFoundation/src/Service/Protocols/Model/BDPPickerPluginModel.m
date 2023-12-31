//
//  BDPPickerPluginModel.m
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import "BDPPickerPluginModel.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

const NSInteger BDPPickerColumnNotUpdate = -1;

@implementation BDPPickerPluginModel

- (instancetype)initWithDictionary:(NSDictionary *)dic error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dic error:err];
    if (self) {
        [self setupArrayWithDic:dic];
        [self setupCurrentWithDic:dic];
    }
    
    return self;
}

- (void)setupArrayWithDic:(NSDictionary *)dic {
    NSArray *arr = [dic bdp_arrayValueForKey:@"array"];
    if ([arr.firstObject isKindOfClass:[NSString class]]) {
        self.components = @[arr];
    } else if ([arr.firstObject isKindOfClass:[NSArray class]]) {
        self.components = arr;
    }
}

- (void)setupCurrentWithDic:(NSDictionary *)dic {
    id current = [dic objectForKey:@"current"];
    if ([current isKindOfClass:[NSArray class]]) {
        self.selectedRows = current;
    } else if ([current isKindOfClass:[NSNumber class]]) {
        self.selectedRows = @[current];
    }
}

- (void)setupColumnWithDic:(NSDictionary *)dic {
    id column = [dic objectForKey:@"column"];
    if (!column) {
        _column = BDPPickerColumnNotUpdate;
    }
}

- (void)updateWithModel:(BDPPickerPluginModel *)model {
    if (model.column == BDPPickerColumnNotUpdate) {
        return;
    }
    
    if (self.components.count <= model.column) {
        return;
    }
    
    // 暂时不支持更新多列
    if (model.components.count != 1) {
        return;
    }
    
    if (model.selectedRows.count != 1) {
        return;
    }
    
    //如果不是数组，可能会引起picker的crash
    if (![model.components.firstObject isKindOfClass:NSArray.class]) {
        return;
    }
    
    NSMutableArray *components = self.components.mutableCopy;
    components[model.column] = model.components.firstObject;
    _components = [components copy];
    
    NSMutableArray *select = self.selectedRows.mutableCopy;
    select[model.column] = model.selectedRows.firstObject;
    _selectedRows = [select copy];
}

@end
