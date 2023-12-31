//
//  TTKitchenInternal.m
//  Pods
//
//  Created by SongChai on 2018/4/18.
//

#import "TTKitchenInternal.h"

@implementation TTKitchenModel
@synthesize freezedValue = _freezedValue;

- (void)setFreezedValue:(id)freezedValue {
    if (!_freezed) { //没有强制内存不变则设置没意义。
        return;
    }
    @synchronized (self) {
        switch (_type) {
            case TTKitchenModelTypeString:
                if ([freezedValue isKindOfClass:[NSString class]]) {
                    _freezedValue = freezedValue;
                }
                break;
            case TTKitchenModelTypeFloat:
                if ([freezedValue isKindOfClass:[NSNumber class]]) {
                    _freezedValue = freezedValue;
                }
                break;
            case TTKitchenModelTypeBOOL:
                if ([freezedValue isKindOfClass:[NSNumber class]]) {
                    _freezedValue = freezedValue;
                }
                break;
            case TTKitchenModelTypeArray:
            case TTKitchenModelTypeStringArray:
            case TTKitchenModelTypeBOOLArray:
            case TTKitchenModelTypeFloatArray:
            case TTKitchenModelTypeArrayArray:
            case TTKitchenModelTypeDictionaryArray:
                if ([freezedValue isKindOfClass:[NSArray class]]) {
                    _freezedValue = freezedValue;
                }
                break;
            case TTKitchenModelTypeDictionary:
            case TTKitchenModelTypeModel:
                if ([freezedValue isKindOfClass:[NSDictionary class]]) {
                    _freezedValue = freezedValue;
                }
                break;
        }
    }
}

- (id)freezedValue {
    @synchronized(self) {
        return _freezedValue;
    }
}

- (void)reset {
    self.freezedValue = nil;
}

@end
