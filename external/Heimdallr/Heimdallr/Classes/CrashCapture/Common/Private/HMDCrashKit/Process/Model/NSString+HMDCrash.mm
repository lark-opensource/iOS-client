//
//  NSString+HMDCrash.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/20.
//

#import <cxxabi.h>
#import "HMDMacro.h"
#import "NSString+HMDCrash.h"

#define HMD_CRASH_UTF8_STACK_ALLOCATION_MAX_LENGTH (1024 * 2)           // 2KB
#define HMD_CRASH_UTF8_HEAP_ALLOCATION_MAX_LENGTH  (1024 * 512)         // 512KB

@implementation NSString (HMDCrash)

/*!@method @p hmdcrash_stringWithHex
   @abstract 将 @p @"1FBC032F" 等用 HEX 代替实际存储数据的字符串( 类似 Base64 编码 )，
   先转换为存储的数据，然后再假定数据是 UTF-8 类型，转换为 UTF-8 字符串
 */
- (NSString * _Nullable)hmdcrash_stringWithHex {
    
    NSUInteger length = self.length;
    
    if(length == 0) return @"";
    if(length % 2 != 0) DEBUG_RETURN(nil);
    
    NSUInteger rawDataLength = length + 1;
    BOOL heapAllocateRawData = NO;
    
    if(rawDataLength > HMD_CRASH_UTF8_STACK_ALLOCATION_MAX_LENGTH) {
        if(rawDataLength > HMD_CRASH_UTF8_HEAP_ALLOCATION_MAX_LENGTH) return nil;
        heapAllocateRawData = YES;
    }
    
    NSUInteger UTF8DataLength = length / 2 + 1;
    BOOL heapAllocateUTF8Data = NO;
    
    if(UTF8DataLength > HMD_CRASH_UTF8_STACK_ALLOCATION_MAX_LENGTH) {
        if(UTF8DataLength > HMD_CRASH_UTF8_HEAP_ALLOCATION_MAX_LENGTH) DEBUG_RETURN(nil);
        heapAllocateUTF8Data = YES;
        DEBUG_ASSERT(heapAllocateRawData);
    }
    
    uint8_t * _Nullable rawData = NULL;
    uint8_t * _Nullable UTF8Data = NULL;
    
    if(heapAllocateRawData) {
        if((rawData = (uint8_t * _Nullable)malloc(rawDataLength)) == NULL)
            return nil;
    } else rawData = (uint8_t * _Nullable)__builtin_alloca(rawDataLength);

    if(heapAllocateUTF8Data) {
        if((UTF8Data = (uint8_t * _Nullable)malloc(UTF8DataLength)) == NULL) {
            DEBUG_ASSERT(rawData != NULL);
            if(heapAllocateRawData) free(rawData);
            return nil;
        }
    } else UTF8Data = (uint8_t * _Nullable)__builtin_alloca(UTF8DataLength);
    
    DEBUG_ASSERT(rawData != NULL);
    DEBUG_ASSERT(UTF8Data != NULL);
    
    NSString *result = nil;
    if([self getCString:(char * _Nonnull)rawData maxLength:rawDataLength encoding:NSUTF8StringEncoding]) {
        
        // explicit mark end of string
        rawData[rawDataLength - 1] = '\0';
        
        NSUInteger rawDataIndex = 0;
        NSUInteger UTF8DataIndex = 0;
        
        uint8_t firstRawHexValue;
        uint8_t secondRawHexValue;
        
        BOOL operationSoundsGood = YES;
        
        while((firstRawHexValue = rawData[rawDataIndex]) != '\0') {
            
            if((secondRawHexValue = rawData[rawDataIndex + 1]) == '\0') {
                operationSoundsGood = NO;
                break;
            }
            
            if(firstRawHexValue >= '0' && firstRawHexValue <= '9')
                firstRawHexValue = firstRawHexValue - '0';
            else if(firstRawHexValue >= 'a' && firstRawHexValue <= 'f')
                firstRawHexValue = firstRawHexValue - 'a' + 10;
            else if(firstRawHexValue >= 'A' && firstRawHexValue <= 'F')
                firstRawHexValue = firstRawHexValue - 'A' + 10;
            else {
                operationSoundsGood = NO;
                break;
            }
            
            if(secondRawHexValue >= '0' && secondRawHexValue <= '9')
                secondRawHexValue = secondRawHexValue - '0';
            else if(secondRawHexValue >= 'a' && secondRawHexValue <= 'f')
                secondRawHexValue = secondRawHexValue - 'a' + 10;
            else if(secondRawHexValue >= 'A' && secondRawHexValue <= 'F')
                secondRawHexValue = secondRawHexValue - 'A' + 10;
            else {
                operationSoundsGood = NO;
                break;
            }
            
            uint8_t character = secondRawHexValue + (firstRawHexValue << 4);
            
            DEBUG_ASSERT(rawDataIndex % 2 == 0);
            DEBUG_ASSERT((rawDataIndex / 2) < UTF8DataLength - 1);
            DEBUG_ASSERT(UTF8DataIndex < UTF8DataLength - 1);
            
            UTF8Data[UTF8DataIndex++] = character;
            
            rawDataIndex += 2;
            
        }   // break exit
        
        if(UTF8DataIndex > 0 && operationSoundsGood) {
            
            UTF8Data[UTF8DataIndex] = '\0';
            
            result = [NSString stringWithUTF8String:(const char * _Nonnull)UTF8Data];
            
        } DEBUG_ELSE
        
    } DEBUG_ELSE    // not HEX encoded ?
    
exitPoint:
    
    if(heapAllocateRawData)  free(rawData);
    if(heapAllocateUTF8Data) free(UTF8Data);
    
    return result;
}

- (NSString * _Nullable)hmdcrash_cxxDemangledString {
    if (self.length == 0) {
        return self;
    }
    int status = 0;
    char *str = __cxxabiv1::__cxa_demangle(self.UTF8String,NULL,NULL,&status);
    NSString *ret = self;
    if (status == 0 && str) {
        ret = [NSString stringWithUTF8String:str];
    }
    if (str) {
        free(str);
    }
    return ret;
}

@end
