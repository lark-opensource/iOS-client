//
//  ACCCutSameLogger.h
//  CameraClient-Pods-Aweme
//
//  Created by wanghongyu on 2021/3/4.
//

#import "ACCCutSameLogger.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCCutSameWorksManagerProtocol.h>

static NSTimeInterval TemplateDownloadStartT = 0;
static NSTimeInterval TemplateDownloadEndT = 0;
static NSTimeInterval ImportStartT = 0;
static NSTimeInterval NLEModelStartT = 0;
static NSTimeInterval LoadingStartT = 0;

void LogCutSameTemplateDownloadStart(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    TemplateDownloadStartT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【template download start】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, TemplateDownloadStartT);
}

void LogCutSameTemplateDownloadEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    TemplateDownloadEndT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【template download end】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, TemplateDownloadEndT);
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【duration】【template download】%@ %lld  %lfms", currentTemplateModel.title, currentTemplateModel.templateID, TemplateDownloadEndT - TemplateDownloadStartT);
}


void LogCutSameTemplateProcessEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    NSTimeInterval TemplateProcessEndT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【template process end】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, TemplateProcessEndT);
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【duration】【template process】%@ %lld %lfms", currentTemplateModel.title, currentTemplateModel.templateID, TemplateProcessEndT - TemplateDownloadEndT);
}

void LogCutSameImportStart(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    ImportStartT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【import start】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, ImportStartT);
}

void LogCutSameImportEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    NSTimeInterval ImportEndT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【import end】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, ImportEndT );
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【duration】【import】%@ %lld %lfms", currentTemplateModel.title, currentTemplateModel.templateID, ImportEndT - ImportStartT);
}

void LogCutSameNLEModelStart(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    NLEModelStartT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【NLEModel start】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, NLEModelStartT);
}

void LogCutSameNLEModelEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    NSTimeInterval NLEModelEndT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【NLEModel end】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, NLEModelEndT);
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【duration】【NLEModel】%@ %lld %lfms",currentTemplateModel.title, currentTemplateModel.templateID, NLEModelEndT - NLEModelStartT);
}

void LogCutSameLoadingStart(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    LoadingStartT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【loading start】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, LoadingStartT);
}

void LogCutSameLoadingEnd(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    NSTimeInterval LoadingEndT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【loading end】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, LoadingEndT);
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cost time】【duration】【loading】%@ %lld %lfms", currentTemplateModel.title, currentTemplateModel.templateID, LoadingEndT - LoadingStartT);
}

void LogCutSameCancel(id<ACCMVTemplateModelProtocol> currentTemplateModel)
{
    NSTimeInterval cancelT = [[NSDate date] timeIntervalSince1970] * 1000;
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】【cancel】%@ %lld at %lf", currentTemplateModel.title, currentTemplateModel.templateID, cancelT);
}

