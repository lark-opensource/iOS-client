//
//  BDPHttpDownloadTask+BrSupport.m
//  Timor
//
//  Created by annidy on 2019/11/12.
//

#import "BDPHttpDownloadTask+BrSupport.h"
#import "brotli/decode.h"
#import <objc/runtime.h>
#import <ECOInfra/BDPLog.h>
#import <LarkStorage/LarkStorage-Swift.h>

#pragma mark Brotli
/// weak实现的解压函数，实际与是否链接ttnet有关
__attribute__ ((weak)) void BrotliDecoderDestroyInstance(BrotliDecoderState* state)
{
    
}

__attribute__ ((weak)) BrotliDecoderState* BrotliDecoderCreateInstance(
brotli_alloc_func alloc_func, brotli_free_func free_func, void* opaque)
{
    return NULL;
}

__attribute__ ((weak)) BrotliDecoderResult BrotliDecoderDecompressStream(
BrotliDecoderState* state, size_t* available_in, const uint8_t** next_in,
size_t* available_out, uint8_t** next_out, size_t* total_out)
{
    return BROTLI_DECODER_RESULT_ERROR;
}


@interface BDPHttpDownloadTask (BrSupport_Inner)
@property (assign) BrotliDecoderState *brState;
@end

static void *MyBrStateKey;

@implementation BDPHttpDownloadTask (BrSupport)

- (void)dealloc
{
    [self releaseBrContext];
}

- (BrotliDecoderState *)brState{
    NSValue *p = objc_getAssociatedObject(self, &MyBrStateKey);
    return [p pointerValue];
}

- (void)setBrState:(BrotliDecoderState *)brState {
    objc_setAssociatedObject(self, &MyBrStateKey, [NSValue valueWithPointer:brState], OBJC_ASSOCIATION_COPY);
}

- (void)setupBrContext
{
    NSCAssert(!self.brState, @"重复初始化Br");
    if (self.brState) {
        BrotliDecoderDestroyInstance(self.brState);
        self.brState = NULL;
    }
    
    self.brState = BrotliDecoderCreateInstance(NULL, NULL, NULL);
}

- (void)releaseBrContext
{
    if (self.brState) {
        BrotliDecoderDestroyInstance(self.brState);
        self.brState = NULL;
    }
}

- (NSData *)brDecode:(NSData *)chunk
{
    if (!self.brState || !chunk.length) {
        return nil;
    }
    
    NSMutableData *data = [[NSMutableData alloc] init];
    BrotliDecoderResult result = BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT;
    size_t available_in = chunk.length;
    const uint8_t *next_in = (uint8_t *)chunk.bytes;
    size_t available_out = chunk.length * 3;
    uint8_t *next_out = malloc(available_out);
    uint8_t *output =  next_out;
    
    while (1) {
        result = BrotliDecoderDecompressStream(self.brState, &available_in,
               &next_in, &available_out, &next_out, 0);
        
        if (result == BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT) {
            [data appendBytes:output length:(next_out-output)];
            next_out = output;
            available_out = chunk.length * 3;
            continue;
        }
        break;
    }
    [data appendBytes:output length:(next_out-output)];
    free(output);
    
    return data.length ? data : nil;
}

/// 简单的方法是在Category中增加load方法，来设置此标记。但代码规范不允许这么做
+ (BOOL)isSupportBr
{
    static BOOL bSupport = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BrotliDecoderState *ins = BrotliDecoderCreateInstance(NULL, NULL, NULL);
        bSupport = (ins != NULL);
        BrotliDecoderDestroyInstance(ins);
    });
    return bSupport;
}

#if DEBUG
+ (void) testTime {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i <= 11; i++) {
            NSString *str = [NSString stringWithFormat:@"https://tt8kp9gn4oeqgoh39x.tt.host.bytedance.net/app.ttpkg.%d.br", i];
            NSData *da = [NSData lss_dataWithContentsOfURL:[NSURL URLWithString:str] error:nil];
            NSTimeInterval start = CFAbsoluteTimeGetCurrent();
            BDPHttpDownloadTask *t = [[BDPHttpDownloadTask alloc] init];
            [t setupBrContext];
            NSData *o = [t brDecode:da];
            [t releaseBrContext];
            BDPLogDebug(@"Level %d, cost time %d ms, data (%lu - %lu)", i, (int)((CFAbsoluteTimeGetCurrent()-start)*1000), da.length, o.length);
        }
    });
    
}
#endif
@end
