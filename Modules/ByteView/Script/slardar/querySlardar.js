/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */

const {get, post} = require('@slardar/open-api')
const appKey = 'app_id_f8ee93f685836dc57c95767f8408f3f7'
const appSecret = '14bf17d004faf680b537cb3518ff8498'
//查询slardar的问题列表
module.exports = async function(params, context) {
  var today = Math.floor((new Date()).getTime()/1000)
  var queryData = {
    aid: 1161,
    os: "iOS",
    region: "cn",
    labels: [],
    group_name: null,
    start_time: today - 30*24*60*60,
    end_time: today,
    crash_type: "crash",
    filters: {},
    filters_conditions: {type: "and", sub_conditions: []},
    managers: ["liuning.cn"],
    status: ["new_created","unassigned","doing","long","be_processed_again"],
    token: "",
    token_type: 0,
    tags: [],
    is_new: false,
    is_parsed: false,
    pgno: 1,
    pgsz: 10,
    order_by: "user_descend",
    simple: false,
    granularity: 86400,
    customQueryClauses: [],
    nonCustomQueryClauses: []
  }
  var url = 'http://apm-open2.bytedance.net/api_v2/app/crash/issue/list/search'
  
  for (var key in params) {
    queryData[key] = params[key]
  }
  var res = await post(url, null,queryData, {appKey:appKey, appSecret:appSecret,timeout:30*1000})
  return res.body.data
}

//查询某个的问题的事件列表
module.exports.queryEvent = async function(params, context) {
  
  var url = "http://apm-open2.bytedance.net/api_v2/app/crash/event/list"
  var today = Math.floor((new Date()).getTime()/1000)

  var queryData = {
    aid: 1161,
    os: "iOS",
    region: "cn",
    start_time: today - 30*24*60*60,
    end_time: today,
    crash_type: "crash",
    issue_id: "1",
    sub_issue_id: "",
    filters_conditions: {type: "and", sub_conditions: []},
    versions_conditions: {},
    token: "",
    pgsz: 10,
    pgno: 1,
  }
  
  for (var key in params) {
    queryData[key] = params[key]
  }

  var res = await post(url, null,queryData, {appKey, appSecret})
  return res.body.data
}
//下载原始日志
module.exports.getLog = async function(params, context) {
  var url = "http://apm-open2.bytedance.net/api_v2/app/crash/event/log/get"
  var queryData = {
    event_id: "",
    device_id: "",
    crash_time: 1581648793,
    region: "cn",
    aid: 1161,
    os: "iOS"
  }

  for (var key in params) {
    queryData[key] = params[key]
  }

  let res = await get(url, queryData,{appKey, appSecret})
  return res.body.data
}

module.exports.queryDetail = async function(params, context) {
  
  //start_time和end_time传什么返回什么。。。。。。。。佛了
  //不知道这个api有啥用，要是这些信息都知道了，还查啥呀。。。
  var url = "http://apm-open2.bytedance.net/api_v2/app/crash/issue/detail "
  var today = Math.floor((new Date()).getTime()/1000)

  var queryData = {
    aid: 1161,
    os: "iOS",
    region: "cn",
    crash_type: "crash",
    issue_id: "",
    start_time: today - 30*24*60*60,
    end_time: today,
  }
  
  for (var key in params) {
    queryData[key] = params[key]
  }

  var res = await post(url, null,queryData, {appKey, appSecret})
  return res.body.data
}

//获取问题发生的所有app版本
module.exports.getAppVersion = async function(params, context) {

  var url = "http://apm-open2.bytedance.net/api_v2/app/crash/issue/field/percent"
  var today = Math.floor((new Date()).getTime()/1000)

  var queryData = {
    aid: 1161,
    os: "iOS",
    region: "cn",
    crash_type: "crash",
    issue_id: "",
    start_time: today - 30*24*60*60,
    end_time: today,
    sub_issue_id: "",
    "filters_conditions": {
        "type": "and",
        "sub_conditions": []
    },
    "versions_conditions": {},
    "token": "",
    "field": "app_version",
    "limit": 20
  }

  for (var key in params) {
    queryData[key] = params[key]
  }

  var res = await post(url, null,queryData, {appKey, appSecret})
  return res.body.data

}

//下载日志，symbolicate是true代表下载解析的日志
module.exports.downloadLog = async function(params){
  var url = "https://apm-open2.bytedance.net/api_v2/app/crash/event/log/download"
  const {aid,event_id,device_id,crash_time} = params 
  var queryData = {
    symbolicate: true,
    event_id: event_id,
    device_id: device_id,
    crash_time: crash_time,
    os: "iOS",
    aid: aid,
    region: "cn",
  }
  var res = await get(url,queryData, {appKey:appKey, appSecret:appSecret,timeout:30*1000})
  return res
}
