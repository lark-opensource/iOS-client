//
//  BDUGShareEvent.h
//  Pods
//
//  Created by 杨阳 on 2019/7/30.
//

#ifndef BDUGShareEvent_h
#define BDUGShareEvent_h

NS_ASSUME_NONNULL_BEGIN

#pragma mark - tracker event

static NSString *const kShareChannelClick = @"ug_sdk_share_channel_click";
static NSString *const kSharePopupShow = @"ug_sdk_share_popup_show";
static NSString *const kSharePopupClick = @"ug_sdk_share_popup_click";
static NSString *const kShareTrackerDisplayPanel = @"ug_sdk_share_panel_show";
static NSString *const kShareAuthorizeRequest = @"ug_sdk_share_authorize_popup_request";
static NSString *const kShareAuthorizeShow = @"ug_sdk_share_authorize_popup_show";
static NSString *const kShareAuthorizeClick = @"ug_sdk_share_authorize_popup_click";
static NSString *const kShareHiddenInterfaceWrite = @"ug_sdk_share_hidden_interface_write";
static NSString *const kShareHiddenInterfaceRead = @"ug_sdk_share_hidden_interface_read";
static NSString *const kShareQRCodeInterfaceRead = @"ug_sdk_share_qrcode_interface_read";
static NSString *const kShareRecognizePopupShow = @"ug_sdk_share_recognize_popup_show";
static NSString *const kShareRecognizePopupClick = @"ug_sdk_share_recognize_popup_click";
static NSString *const kShareEventRecognizeInterfaceRequest = @"ug_sdk_share_recognize_interface_request";
static NSString *const kShareEventInitialInterfaceRequest = @"ug_sdk_share_initial_interface_request";
static NSString *const kShareEventInfoInterfaceRequest = @"ug_sdk_share_info_interface_request";
static NSString *const kShareEventShareSuccess = @"ug_sdk_share_share_success";

#pragma mark - monitor event

static NSString *const kShareMonitorInitial = @"ug_sdk_share_initial_interface_request";
static NSString *const kShareMonitorInfo = @"ug_sdk_share_info_interface_request";
static NSString *const kShareMonitorTokenInfo = @"ug_sdk_share_recognize_interface_request";
static NSString *const kShareMonitorHiddenmarkWrite = @"ug_sdk_share_hidden_interface_write";
static NSString *const kShareMonitorHiddenmarkRead = @"ug_sdk_share_hidden_interface_read";
static NSString *const kShareMonitorQRCodeRead = @"ug_sdk_share_qrcode_interface_read";
static NSString *const kShareMonitorDisplayPanel = @"ug_sdk_share_panel_show";
static NSString *const kShareMonitorItemClick = @"ug_sdk_share_channel_clicked_failed";
static NSString *const kShareMonitorVideoDownload = @"ug_sdk_share_video_download";
static NSString *const kShareMonitorImageDownload = @"ug_sdk_share_image_download";
static NSString *const kShareMonitorFileDownload = @"ug_sdk_share_file_download";
static NSString *const kShareMonitorVideoDownloadDuration = @"ug_sdk_share_video_download_duration";

NS_ASSUME_NONNULL_END

#endif /* BDUGShareEvent_h */


