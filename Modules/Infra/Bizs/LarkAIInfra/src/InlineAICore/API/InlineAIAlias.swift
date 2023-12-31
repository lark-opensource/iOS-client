//
//  InlineAIAlias.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/18.
//  


import RustPB
import ServerPB

//typealias InlineAITaskStatusPushResponse = InlineAITaskStatusPushResponse

typealias QuickActionResponse = ServerPB_Office_ai_inline_FetchQuickActionResponse

typealias CreateTaskResponse = Space_Doc_V1_InlineAICreateTaskResponse

typealias InlineAIPushResponse = Space_Doc_V1_InlineAITaskStatusPushResponse

typealias InlineAITaskStatus = Space_Doc_V1_InlineAITaskStatus

typealias CancelTaskResponse = Space_Doc_V1_InlineAICancelTaskResponse

typealias RecentPromptResponse = ServerPB_Office_ai_inline_GetRecentActionsResponse

typealias RecentAction = ServerPB_Office_ai_inline_HistoryAction

typealias DeleteActionResponse = ServerPB_Office_ai_inline_DeleteActionResponse

public typealias InlineAIQuickAction = ServerPB_Office_ai_inline_QuickAction


typealias SendHttpRequest = RustPB.Basic_V1_SendHttpRequest
typealias SendHttpResponse = RustPB.Basic_V1_SendHttpResponse
