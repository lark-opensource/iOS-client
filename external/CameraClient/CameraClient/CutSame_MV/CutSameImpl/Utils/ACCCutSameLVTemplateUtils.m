//
//  ACCCutSameLVTemplateUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/24.
//

#import "ACCCutSameLVTemplateUtils.h"

@interface ACCLVTemplateFragment : NSObject<LVTemplateFragment>

@property (nonatomic, copy) NSString *payloadID; // 替换资源ID
@property (nonatomic, copy) NSString *resourceID; // 用来生成文件名
@property (nonatomic, assign) CMTimeRange sourceTimeRange; // 片段原始资源时间范围
@property (nonatomic, copy) NSArray<NSValue *> *cropPoints; // 该资源显示的范围，归一化坐标，4个CGPoint
@property (nonatomic, assign) CGSize videoSzie; // 原始视频的大小

@end

@implementation ACCLVTemplateFragment

@end

@interface ACCLVVideoTemplateFragment : ACCLVTemplateFragment<LVTemplateVideoFragment>

@property (nonatomic, copy) NSString *videoPath; // 视频路径

@end

@implementation ACCLVVideoTemplateFragment

@synthesize cartoonFilePath;

@synthesize cartoonOutputType;

@end

@interface ACCLVImageTemplateFragment : ACCLVTemplateFragment<LVTemplateImageFragment>

@property (nonatomic, strong) NSData *imageData; // 图片数据
@property (nonatomic, assign) CGSize imageSize; // 图片Size

@property (nonatomic, strong, nullable) NSString *cartoonFilePath;
@property (nonatomic, assign) BOOL isCartoon;

@end

@implementation ACCLVImageTemplateFragment

@synthesize cartoonOutputType;

@synthesize cartoonFilePath;

@end

@implementation ACCCutSameLVTemplateUtils

+ (id<LVTemplateFragment>)createTemplateWithFragment:(id<ACCCutSameFragmentModelProtocol>)fragment
{
    ACCLVTemplateFragment *result = [[ACCLVTemplateFragment alloc] init];
    result.payloadID = fragment.materialId;
    result.resourceID = [NSUUID UUID].UUIDString;
    result.sourceTimeRange = CMTimeRangeFromTimeToTime(CMTimeMake(0, USEC_PER_SEC), CMTimeMake(fragment.duration.integerValue, 1000));
    result.videoSzie = CGSizeMake(fragment.videoWidth.doubleValue, fragment.videoHeight.doubleValue);
    
    return result;
}

+ (id<LVTemplateImageFragment>)createImageTemplateWithFragment:(id<ACCCutSameFragmentModelProtocol>)fragment
{
    ACCLVImageTemplateFragment *result = [[ACCLVImageTemplateFragment alloc] init];
    result.payloadID = fragment.materialId;
    result.resourceID = [NSUUID UUID].UUIDString;
    result.sourceTimeRange = CMTimeRangeFromTimeToTime(CMTimeMake(0, USEC_PER_SEC), CMTimeMake(fragment.duration.integerValue, 1000));
    result.videoSzie = CGSizeMake(fragment.videoWidth.doubleValue, fragment.videoHeight.doubleValue);
    
    return result;
}

+ (id<LVTemplateVideoFragment>)createVideoTemplateWithFragment:(id<ACCCutSameFragmentModelProtocol>)fragment
{
    ACCLVVideoTemplateFragment *result = [[ACCLVVideoTemplateFragment alloc] init];
    result.payloadID = fragment.materialId;
    result.resourceID = [NSUUID UUID].UUIDString;
    result.sourceTimeRange = CMTimeRangeFromTimeToTime(CMTimeMake(0, USEC_PER_SEC), CMTimeMake(fragment.duration.integerValue, 1000));
    result.videoSzie = CGSizeMake(fragment.videoWidth.doubleValue, fragment.videoHeight.doubleValue);
    
    return result;
}

@end

@implementation NSArray (ACCCutSameFragmentModelLVTemplate)

- (NSArray<id<LVTemplateFragment>> *)createTemplateFragmentArray
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(ACCCutSameFragmentModelProtocol)]) {
            id r = [ACCCutSameLVTemplateUtils createTemplateWithFragment:obj];
            if (r) {
                [array addObject:r];
            }
        }
    }];
    
    return array;
}

@end
