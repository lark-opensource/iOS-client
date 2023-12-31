/**
 * @param {*} params 函数调用参数，HTTP 调用场景下为请求体
 *
 * @param {*} context 调用上下文
 * @param {string} context.method HTTP 请求的 Method
 * @param {object} context.query HTTP 请求的 queryString
 * @param {object} context.headers HTTP 请求的 headers
 * @param {string} context.body HTTP 请求的 body
 *
 * @return {*} 函数的返回数据，HTTP 场景下会作为 Response Body
 */

// testing function
module.exports = async function(params, context) {
  console.log(params);
  const client = await module.exports.client()
  console.log(client)
  return {}
}

const get_token = async function() {
  var token = await bc.redis.get("tenant_access_token")
  console.log(token)
  if ( token ) {
    return token
  }

  var app_id = bc.env.VC_APP_ID
  var app_secret = bc.env.VC_APP_SECRET

  const post_res = await axios.post('https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/', {
     "app_id":app_id,
    "app_secret":app_secret })

  console.log(post_res.data)
  token = post_res.data.tenant_access_token;
  var res = await bc.redis.setex("tenant_access_token", post_res.data.expire - 10, token)
  return token;
}

module.exports.client = async function() {
  const token = await get_token()
  return axios.create({
  baseURL: 'https://open.feishu.cn/open-apis',
  headers: {
    common: {
      'Authorization': 'Bearer ' + token
    }
  }
});
}