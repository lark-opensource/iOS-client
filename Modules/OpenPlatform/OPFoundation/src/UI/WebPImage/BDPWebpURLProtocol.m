//
//  BDPWebpURLProtocol.m
//  Timor
//
//  Created by MacPu on 2019/10/16.
//

#import "BDPWebpURLProtocol.h"
#import "UIImage+BDPExtension.h"

#import <BDWebImage/UIImage+BDWebImage.h>
#import <ECOInfra/EMAFeatureGating.h>

#define BDP_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
static NSString *kBDPWebpURLProtocolKey = @"kBDPWebpURLProtocolKey";

@interface BDPWebpURLProtocol() <NSURLSessionDelegate>

@property (nonatomic, weak) NSURLSessionTask *task;

@end

@implementation BDPWebpURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *scheme = [[request URL] scheme];
    
    return ([scheme isEqualToString:@"ttwebp"] || [scheme isEqualToString:@"ttwebps"]) &&  // schema 必须是 ttwebp 或者 ttwebps
           ![NSURLProtocol propertyForKey:kBDPWebpURLProtocolKey inRequest:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:YES];
    if ([components.scheme isEqualToString:@"ttwebps"]) {
        components.scheme = @"https";
    } else if ([components.scheme isEqualToString:@"ttwebp"]) {
        components.scheme = @"http";
    }
    mutableReqeust.URL = components.URL;
    return mutableReqeust;
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kBDPWebpURLProtocolKey inRequest:mutableReqeust];
    
    //webp判断本地是否有缓存
    if ([mutableReqeust.URL.pathExtension caseInsensitiveCompare:@"webp"] == NSOrderedSame) {
       NSString *name = [NSString stringWithFormat:@"%ld.png", (long)self.request.URL.absoluteString.hash];
       // lint:disable:next lark_storage_check
       NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
       if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
           mutableReqeust.URL = [NSURL fileURLWithPath:path];
       }
    }
    
    self.task = [[NSURLSession sharedSession] dataTaskWithRequest:mutableReqeust completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
        /**
         修复小程序image组件加载webp图片引发crash的问题：
         URLProtocol:didFailWithError:需要放在URLProtocol:didReceiveResponse:cacheStoragePolicy:方法前面返回，否则在处理一些网络请求（e.g. https://imgsec.xiaozhustatic1.com/imgshowsource/00,648,504,1,100,1/13,0,87,17825,1499,2000,d8582889.webp）时会crash
         */
        // 如果有error就证明是网络失败了
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSMutableDictionary *header =  [httpResponse.allHeaderFields mutableCopy];
        [header setValue:@"image/png" forKey:@"Content-Type"];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
        
        // 网络成功的情况下
        NSString *extension = [response.URL pathExtension];
        // 做网络的情况
        if ([extension caseInsensitiveCompare:@"webp"] == NSOrderedSame) {
            UIImage *imageData = nil;
            // 先判断是否真的是webp格式的图片
            if ([self isWebpData:data]) {
                if ([EMAFeatureGating boolValueForKey:@"openplatform.api.ios_image_component_webp_unify"]) {
                    // 尝试废弃imageWithWebPData分类，开关全量一段时间后可以去掉无用UIImage分类代码
                    imageData = [UIImage bd_imageWithData:data];
                } else if (@available(iOS 16.0, *)) {
                    if ([EMAFeatureGating boolValueForKey:@"openplatform.api.fix_image_component_ios16_webp"]) {
                        imageData = [UIImage bd_imageWithData:data];
                    } else {
                        imageData = [UIImage imageWithWebPData:data];
                    }
                } else {
                    imageData = [UIImage imageWithWebPData:data];
                }
            } else {
                imageData = [UIImage imageWithData:data];
            }
            NSData *pngData = UIImagePNGRepresentation(imageData);
            NSString *name = [NSString stringWithFormat:@"%ld.png", (long)response.URL.absoluteString.hash];
            // lint:disable:next lark_storage_check
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
            [pngData writeToFile:path atomically:YES];
            
            [self.client URLProtocol:self didLoadData:pngData];
        }
        else {
            // 走缓存的情况
            [self.client URLProtocol:self didLoadData:data];
        }
        [self.client URLProtocolDidFinishLoading:self];
    }];
    
    [self.task resume];
}

- (void)stopLoading
{
    [self.task cancel];
}

- (BOOL)isWebpData:(NSData *)data
{
    CFDataRef mData = (__bridge CFDataRef)data;
    if (!mData) return NO;
    CFIndex length = CFDataGetLength(mData);
    if (length < 16) return NO;
    const char *bytes = (char *)CFDataGetBytePtr(mData);
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) return NO;
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return NO;
    
    uint32_t magic4 = *((uint32_t *)bytes);
    if (magic4 == BDP_FOUR_CC('R', 'I', 'F', 'F')) {
        uint32_t tmp = *((uint32_t *)(bytes + 8));
        return tmp == BDP_FOUR_CC('W', 'E', 'B', 'P');
    }
    return NO;
}

@end
