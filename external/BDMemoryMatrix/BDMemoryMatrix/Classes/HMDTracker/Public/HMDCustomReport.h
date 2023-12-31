//
//  HMDCustomReport.hpp
//  BDMemoryMatrix
//
//  Created by Ysurfer on 2023/3/31.
//

#ifndef HMDCustomReport_hpp
#define HMDCustomReport_hpp

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
void matrixCustomCollect(void);
void matrixCustomCollectWithInfo(char *customInfo);//支持业务传入自定义信息，作为筛选项区分不同的时机
#ifdef __cplusplus
}
#endif

@interface HMDCustomReport: NSObject
@end

#endif /* HMDCustomReport_hpp */





