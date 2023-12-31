//
//  FocusStatusDesc.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2022/12/28.
//

import Foundation
import RustPB

public typealias FocusStatusDescRichText = RustPB.Basic_V1_RichText

/// 状态说明结构
///
/// ```
/// struct FocusStatusDesc {
///     var richText: Basic_V1_RichText                                         // 富文本信息
///     var urlHangPointMap: Dictionary<String,Basic_V1_PreviewHangPoint>       // HangPoint 映射 （anchorId, hangPoint）
///     var urlPreviewEntityMap: Dictionary<String,Basic_V1_UrlPreviewEntity>   // entity 映射 （previewId, previewEntity）
/// }
/// ```
public typealias FocusStatusDesc = RustPB.Basic_V1_StatusDesc
