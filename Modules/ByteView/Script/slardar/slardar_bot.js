/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */
const reply = require('./rebot_reply');
module.exports = async function(params, context) {
  // 使用 console.log 输出的信息，函数上线后可以在「日志」页中查看
  console.log('message received:', params);

  // verify
  if (params.type == "url_verification") {
    return params
  }
  // 首先校验 token，确定该请求来自 Lark 平台方
  // 请注意将 YOUR_VERIFICATION_TOKEN 替换成你自己应用的 Verification Token
  if (!params || params.token !== 'k3hQwyK6qKJJs8ZNnJ6LlpnvdZasJQOE') {
    return { error: 1, msg: 'Token not valid.' };
  }
  
  const { event } = params;
  await reply(event)
  // 返回 challenge 值用于校验
  return {
    error: 0
  };
}