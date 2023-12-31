//
//  ACCCutSameLogger.h
//  CameraClient
//
//  Created by wanghongyu on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCCutSameWorksManagerProtocol.h>

#ifdef __cplusplus
extern "C" {
#endif

void LogCutSameTemplateDownloadStart(id<ACCMVTemplateModelProtocol> currentTemplateModel);
void LogCutSameTemplateDownloadEnd(id<ACCMVTemplateModelProtocol>  currentTemplateModel);
void LogCutSameTemplateProcessEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel);

void LogCutSameImportStart(id<ACCMVTemplateModelProtocol> currentTemplateModel);
void LogCutSameImportEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel);

void LogCutSameNLEModelStart(id<ACCMVTemplateModelProtocol> currentTemplateModel);
void LogCutSameNLEModelEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel);

void LogCutSameLoadingStart(id<ACCMVTemplateModelProtocol> currentTemplateModel);
void LogCutSameLoadingEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel);

void LogCutSameCancel(id<ACCMVTemplateModelProtocol> currentTemplateModel);

#ifdef __cplusplus
}
#endif
