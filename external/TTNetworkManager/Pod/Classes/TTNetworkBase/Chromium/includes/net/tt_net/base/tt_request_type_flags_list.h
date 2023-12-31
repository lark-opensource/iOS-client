// Copyright (c) 2022 The Bytedance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

TT_REQ_FLAG(NORMAL, 0)

TT_REQ_FLAG(WEBVIEW_REQ, 1 << 0)

TT_REQ_FLAG(DO_NOT_SEND_COOKIE, 1 << 1)

TT_REQ_FLAG(ENABLE_EARLY_DATA, 1 << 2)

TT_REQ_FLAG(DOWNLOAD_REQ, 1 << 3)

TT_REQ_FLAG(NATIVE_REQ, 1 << 4)