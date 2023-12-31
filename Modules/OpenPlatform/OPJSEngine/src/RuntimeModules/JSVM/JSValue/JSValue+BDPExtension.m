//
//  JSValue+BDPExtension.m
//  Timor
//
//  Created by MacPu on 2019/6/11.
//

#import "JSValue+BDPExtension.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation JSValue (BDPExtension)

/**
 newBridge在灰度过程中没有对齐arraybuffer处理协议，使用下面函数进行处理。
 原__nativeBuffer__为base64数据格式，走decodeNativeBuffersIfNeed逻辑处理，数据结构如下：
 {
     data: {
         "param1": "value1",
         "param2": "value2",
         "__nativeBuffers__": [
             {
                 key: "testKey1",
                 base64: "testValue1" // type string
             },
             {
                 key: "testKey1",
                 base64: "testValue2" // type string
             }
         ]
     }
     apiName: "xxx",
     callbackID: "xxx",
     extra: {}
 }

 新__nativeBuffer__为arrayBuffer格式，走bdp_convert2Object逻辑处理，数据结构如下：
 
 {
     data: {
         "param1": "value1",
         "param2": "value2",
         "__nativeBuffers__": [
             {
                 key: "testKey1",
                 value: testArrayBuffer1  // type arrayBuffer
             },
             {
                 key: "testKey2",
                 value: testArrayBuffer2  // type arrayBuffer
             }
         ]
     }
     apiName: "xxx",
     callbackID: "xxx",
     extra: {}
 }
 */
- (NSDictionary *)bdp_convert2Object
{
    NSDictionary *object = nil;
    if ([self isObject]) {
        object = [self toObject];
    }
    // 如果解析失败，或者不是NSDictionary， 直接返回nil
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *data = [object bdp_dictionaryValueForKey:@"data"];
    
    // 如果没有 arrayBuffer的值，就直接返回object.
    NSArray<NSDictionary *> *buffers = [data bdp_arrayValueForKey:@"__nativeBuffers__"];
    if (!buffers.count) {
        return object;
    }

    JSContextRef ctx = [self.context JSGlobalContextRef];
    JSValueRef valueRef = [self JSValueRef];
    JSValueRef exceptionRef;
    JSObjectRef objectRef = JSValueToObject(ctx, valueRef, &exceptionRef);
    JSValueRef dataRef = JSObjectGetProperty(ctx, objectRef, JSStringCreateWithUTF8CString("data"), &exceptionRef);
    NSMutableDictionary *resultDic = [object mutableCopy];
    NSMutableDictionary *newDict = [data mutableCopy];
    NSDictionary *dataDict = [self handleNativeBuffer:newDict ctx:ctx valueRef:dataRef];
    [resultDic setValue:dataDict forKey:@"data"];
    return [resultDic copy];
}

- (NSDictionary *)bdp_object
{
    NSDictionary *object = nil;
    if ([self isObject]) {
        object = [self toObject];
    }
    // 如果解析失败，或者不是NSDictionary， 直接返回nil
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    // 如果没有 arrayBuffer的值，就直接返回object.
    NSArray<NSDictionary *> *buffers = [object bdp_arrayValueForKey:@"__nativeBuffers__"];
    if (!buffers.count) {
        return object;
    }
    
    NSMutableDictionary *newDict = [object mutableCopy];
    JSContextRef ctx = [self.context JSGlobalContextRef];
    JSValueRef valueRef = [self JSValueRef];
    NSDictionary *result = [self handleNativeBuffer:newDict ctx:ctx valueRef:valueRef];
    return result;
}

- (NSDictionary *) handleNativeBuffer:(NSDictionary *)dic ctx:(JSContextRef)ctx valueRef:(JSValueRef)valueRef {
    NSMutableDictionary *newDict = [dic mutableCopy];
    [newDict removeObjectForKey:@"__nativeBuffers__"];
    JSValueRef exceptionRef;
    JSObjectRef objectRef = JSValueToObject(ctx, valueRef, &exceptionRef);
    JSValueRef arrayBufferRef = JSObjectGetProperty(ctx, objectRef, JSStringCreateWithUTF8CString("__nativeBuffers__"), &exceptionRef);
    if (JSValueIsArray(ctx, arrayBufferRef)) {
        JSValueRef countRef = JSObjectGetProperty(ctx, JSValueToObject(ctx, arrayBufferRef, &exceptionRef), JSStringCreateWithUTF8CString("length"), &exceptionRef);
        int count = JSValueToNumber(ctx, countRef, &exceptionRef);

        for (int i = 0; i < count ; i++) {
            JSValueRef bufferRef = JSObjectGetPropertyAtIndex(ctx, JSValueToObject(ctx, arrayBufferRef, &exceptionRef), i, &exceptionRef);
            JSObjectRef bufferObjectRef = JSValueToObject(ctx, bufferRef, &exceptionRef);
            JSValueRef keyRef = JSObjectGetProperty(ctx, bufferObjectRef, JSStringCreateWithUTF8CString("key"), &exceptionRef);
            JSValueRef dataRef = JSObjectGetProperty(ctx, bufferObjectRef, JSStringCreateWithUTF8CString("value"), &exceptionRef);
            NSString *key = nil;
            NSData *data = nil;
            if (JSValueIsString(ctx, keyRef)) {
                JSStringRef keyString = JSValueToStringCopy(ctx, keyRef, &exceptionRef);
                key = (__bridge NSString *)JSStringCopyCFString(kCFAllocatorDefault, keyString);
            }
            JSTypedArrayType type = JSValueGetTypedArrayType(ctx, dataRef, &exceptionRef);
            if (type == kJSTypedArrayTypeArrayBuffer) {
                JSObjectRef dataObjectRef = JSValueToObject(ctx, dataRef, NULL);
                size_t length = JSObjectGetArrayBufferByteLength(ctx, dataObjectRef, NULL);
                void *buffer = JSObjectGetArrayBufferBytesPtr(ctx, dataObjectRef, NULL);
                data = [NSData dataWithBytes:buffer length:length];
            }
            if (key && data) {
                [newDict setValue:data forKey:key];
            }
        }
    }
    return [newDict copy];
}

@end
