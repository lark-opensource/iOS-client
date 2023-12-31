// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_page_agent_ng.h"

#include "agent/devtool_agent_ng.h"
#include "base/screen_metadata.h"
#include "element/element_helper.h"

namespace lynxdev {
namespace devtool {

#define BANNER ""

InspectorPageAgentNG::InspectorPageAgentNG() {
  functions_map_["Page.enable"] = &InspectorPageAgentNG::Enable;
  functions_map_["Page.canEmulate"] = &InspectorPageAgentNG::CanEmulate;
  functions_map_["Page.canScreencast"] = &InspectorPageAgentNG::CanScreencast;
  functions_map_["Page.getResourceTree"] =
      &InspectorPageAgentNG::GetResourceTree;
  functions_map_["Page.getResourceContent"] =
      &InspectorPageAgentNG::GetResourceContent;
  functions_map_["Page.setShowViewportSizeOnResize"] =
      &InspectorPageAgentNG::SetShowViewportSizeOnResize;
  functions_map_["Page.startScreencast"] =
      &InspectorPageAgentNG::StartScreencast;
  functions_map_["Page.stopScreencast"] = &InspectorPageAgentNG::StopScreencast;
  functions_map_["Page.screencastFrameAck"] =
      &InspectorPageAgentNG::ScreencastFrameAck;
  functions_map_["Page.screencastVisibilityChanged"] =
      &InspectorPageAgentNG::ScreencastVisibilityChanged;
  functions_map_["Page.reload"] = &InspectorPageAgentNG::Reload;
  functions_map_["Page.navigate"] = &InspectorPageAgentNG::Navigate;
}

InspectorPageAgentNG::~InspectorPageAgentNG() = default;

void InspectorPageAgentNG::Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  SendWelcomeMessage(devtool_agent);
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::CanScreencast(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["result"] = true;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::CanEmulate(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["result"] = true;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::GetResourceTree(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value frameTree(Json::ValueType::objectValue);
  frameTree["frame"] = Json::ValueType::objectValue;
  frameTree["frame"]["id"] = kDefaultFrameId;
  frameTree["frame"]["loaderId"] = kDefaultLoaderId;
  frameTree["frame"]["url"] = kLynxLocalUrl;
  frameTree["frame"]["securityOrigin"] = kLynxSecurityOrigin;
  frameTree["frame"]["mimeType"] = kLynxMimeType;
  frameTree["resources"] = Json::ValueType::arrayValue;
  content["frameTree"] = frameTree;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::GetResourceContent(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["base64Encoded"] = false;
  std::string html_content = "";
  auto root = devtool_agent->GetRoot();
  if (root != nullptr) {
    html_content = ElementHelper::GetElementContent(root, 0);
  }
  content["content"] = html_content;
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::SetShowViewportSizeOnResize(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content = Json::Value(Json::ValueType::objectValue);
}

void InspectorPageAgentNG::GetNavigationHistory(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content = Json::Value(Json::ValueType::objectValue);
}

void InspectorPageAgentNG::NotifExecutionContext(
    std::shared_ptr<DevToolAgentNG> devtool_agent) {
  Json::Value content;
}

void InspectorPageAgentNG::SendWelcomeMessage(
    std::shared_ptr<DevToolAgentNG> devtool_agent) {
  Json::Value content;
  Json::Value params;
  Json::Value message;

  auto ts = lynx::base::CurrentTimeMilliseconds();

  message["source"] = "javascript";
  message["level"] = "verbose";
  message["text"] = BANNER;
  message["timestamp"] = ts;
  params["entry"] = message;
  content["method"] = "Log.entryAdded";
  content["params"] = params;
  devtool_agent->SendResponseAsync(content);
}

void InspectorPageAgentNG::StartScreencast(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  TriggerFrameNavigated(devtool_agent);

  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  ScreenRequest screen_request;
  screen_request.format_ = params["format"].asString();
  screen_request.quality_ = params["quality"].asInt();
  screen_request.max_width_ = params["maxWidth"].asInt();
  screen_request.max_height_ = params["maxHeight"].asInt();
  screen_request.every_nth_frame_ = params["everyNthFrame"].asInt();
  devtool_agent->StartScreenCast(std::move(screen_request));
#if !ENABLE_RENDERKIT
  content["screen"] = true;
#endif
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::StopScreencast(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  devtool_agent->StopScreenCast();
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::ScreencastFrameAck(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::ScreencastVisibilityChanged(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  content["method"] = "Page.screencastVisibilityChanged";
  content["params"] = params;
  devtool_agent->SendResponseAsync(content);
}

void InspectorPageAgentNG::Reload(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];

  bool ignore_cache = false;
  std::string template_bin = "";
  bool from_template_fragments = false;
  int32_t template_size = 0;
  if (!params.empty()) {
    ignore_cache = params["ignoreCache"].asBool();
    template_bin = params["pageData"].asString();
    from_template_fragments = params["fromPageDataFragments"].asBool();
    template_size = params["pageDataLength"].asInt();
  }

  devtool_agent->PageReload(ignore_cache, std::move(template_bin),
                            from_template_fragments, template_size);

  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPageAgentNG::Navigate(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];
  auto url = params["url"].asString();
  content["frameId"] = "";
  content["loaderId"] = "";
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
  if (url == "about:blank") {
    Json::Value msg;
    msg["method"] = "Page.frameNavigated";
    msg["params"] = Json::ValueType::objectValue;
    msg["params"]["frame"] = Json::ValueType::objectValue;
    msg["params"]["frame"]["url"] = url;
    msg["params"]["frame"]["id"] = "";
    devtool_agent->SendResponseAsync(msg);
  } else {
    devtool_agent->Navigate(url);
  }
}

void InspectorPageAgentNG::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr) {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(
        std::static_pointer_cast<DevToolAgentNG>(devtool_agent), message);
  }
}

void InspectorPageAgentNG::TriggerFrameNavigated(
    const std::shared_ptr<DevToolAgentNG>& devtool_agent) {
  Json::Value msg;
  msg["method"] = "Page.frameNavigated";
  msg["params"] = Json::ValueType::objectValue;
  msg["params"]["frame"] = Json::ValueType::objectValue;
  msg["params"]["frame"]["url"] = "sslocal://lynx";
  // FIXME(zhengyuwei): this code commented by songshourui
  // the reason why this code is commented is unknown，probabay for debugging
  // devtool_agent->SendResponse(msg.toStyledString());
}

}  // namespace devtool
}  // namespace lynxdev
