//
//  AWEVideoEffectChooseSimplifiedCellModel.m
//  Indexer
//
//  Created by Daniel on 2021/11/18.
//

#import "AWEVideoEffectChooseSimplifiedCellModel.h"

@implementation AWEVideoEffectChooseSimplifiedCellModel

- (AWEEffectDownloadStatus)getNextStatus
{
    AWEEffectDownloadStatus result = AWEEffectDownloadStatusUndownloaded;
    switch (self.downloadStatus) {
        case AWEEffectDownloadStatusDownloadFail:
        case AWEEffectDownloadStatusUndownloaded:
            result = AWEEffectDownloadStatusDownloading;
            break;
        case AWEEffectDownloadStatusDownloading:
        case AWEEffectDownloadStatusDownloaded:
            result = AWEEffectDownloadStatusDownloaded;
            break;
        default:
            result = AWEEffectDownloadStatusDownloaded;
    }
    return result;
}

@end
