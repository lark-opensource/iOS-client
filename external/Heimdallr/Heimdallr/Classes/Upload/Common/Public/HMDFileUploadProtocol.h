//
//  HMDFileUploadProtocol.h
//  Heimdallr
//
//  Created by fengyadong on 2018/12/25.
//

#import <Foundation/Foundation.h>
#import "HMDFileUploadRequest.h"

@protocol HMDFileUploadProtocol <NSObject>

@required

/**
 Heimdallr上传文件专用接口
 
 * @param request 构造的上报请求，需要设置的参数有：
 * - filePath: 必填，待上报的文件路径
 * - logType: 必填，文件类型，请不要起的太通用，容易冲突
 * - scene: 必填，文件上报时的场景，e.g.,'crash', 'feedback'
 * - commonParams: 选填，除文件之外的其他自定义参数
 * - path: 选填，上报接口的path，默认/monitor/collect/c/logcollect
 * - byUser: 必填，是否由用户主动触发上报，决定是否降级，默认NO
 * - finishBlock: 选填，完成回调
 */
- (void)uploadFileWithRequest:(nonnull HMDFileUploadRequest *)request;

@end
