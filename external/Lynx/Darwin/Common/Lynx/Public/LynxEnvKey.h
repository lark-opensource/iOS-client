// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXENVKEY_H_
#define DARWIN_COMMON_LYNX_LYNXENVKEY_H_

#import <Foundation/Foundation.h>

static NSString *const SP_KEY_ENABLE_AUTOMATION = @"enable_automation";

// Keys for devtool.
static NSString *const KEY_LYNX_DEBUG = @"enable_lynx_debug";
static NSString *const KEY_DEVTOOL_COMPONENT_ATTACH = @"devtool_component_attach";
static NSString *const SP_KEY_ENABLE_DEVTOOL = @"enable_devtool";
static NSString *const SP_KEY_ENABLE_DEVTOOL_FOR_DEBUGGABLE_VIEW =
    @"enable_devtool_for_debuggable_view";
static NSString *const SP_KEY_ENABLE_REDBOX = @"enable_redbox";
static NSString *const SP_KEY_ENABLE_REDBOX_NEXT = @"enable_redbox_next";
static NSString *const SP_KEY_ENABLE_V8 = @"enable_v8";
static NSString *const SP_KEY_ENABLE_DOM_TREE = @"enable_dom_tree";
static NSString *const SP_KEY_ENABLE_LONG_PRESS_MENU = @"enable_long_press_menu";
static NSString *const SP_KEY_ENABLE_PERF_MONITOR_DEBUG = @"enable_perf_monitor_debug";
static NSString *const SP_KEY_IGNORE_ERROR_TYPES = @"ignore_error_types";
static NSString *const SP_KEY_ENABLE_IGNORE_ERROR_CSS = @"error_code_css";
static NSString *const SP_KEY_ENABLE_PREVIEW_SCREEN_SHOT = @"enable_preview_screen_shot";
static NSString *const SP_KEY_ACTIVATED_CDP_DOMAINS = @"activated_cdp_domains";
static NSString *const SP_KEY_ENABLE_CDP_DOMAIN_DOM = @"enable_cdp_domain_dom";
static NSString *const SP_KEY_ENABLE_CDP_DOMAIN_CSS = @"enable_cdp_domain_css";
static NSString *const SP_KEY_ENABLE_CDP_DOMAIN_PAGE = @"enable_cdp_domain_page";
static NSString *const SP_KEY_DEVTOOL_CONNECTED = @"devtool_connected";
static NSString *const SP_KEY_ENABLE_QUICKJS_DEBUG = @"enable_quickjs_debug";
// deprecated after Lynx2.9
static NSString *const SP_KEY_SHOW_DEVTOOL_BADGE = @"show_devtool_badge";

#endif  // DARWIN_COMMON_LYNX_LYNXENVKEY_H_
