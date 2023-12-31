// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_BASE_BASE_EXPORT_H_
#define LYNX_BASE_BASE_EXPORT_H_

#ifdef NO_EXPORT
#define BASE_EXPORT
#define BASE_EXPORT_FOR_DEVTOOL
#else  // NO_EXPORT
#define BASE_EXPORT __attribute__((visibility("default")))
#define BASE_EXPORT_FOR_DEVTOOL __attribute__((visibility("default")))
#endif  // NO_EXPORT

#endif  // LYNX_BASE_BASE_EXPORT_H_
