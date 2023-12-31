/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */
var JiraClient = require('jira-connector');
const {queryEvent,getLog,getAppVersion,queryDetail,downloadLog} = require('./querySlardar') 
// var jira = new JiraClient({
//     host: 'ee.byted.org/jira-dev',
//     basic_auth: {
//       base64: 'YWRtaW46YWRtaW4='
//     }
// });

var jira = new JiraClient({
    host: 'jira.bytedance.com',
    basic_auth: {
      base64: 'd2VpeXVuaW5nOld3eW45MTM1NTgxMQ=='
    }
});

module.exports = async function(params,context){
  const res = await queryJira(params)
  console.log(res)
}

async function createJira(params, context) {
  let description = await createDescription(params)
  let crash_type = params.crash_type
  let aid = Number(params.aid)
  let issue_id = params.issue_id
  const detailRes = await queryDetail({
    aid:aid,
    crash_type:crash_type,
    issue_id: issue_id,
  })
  let jiraTitle = detailRes.event_detail.trim().replace("[","【").replace("]","】")
  let name = detailRes.title
  let stack = getStack(name)
  
  let data = {
    "update": {},
    "fields": {
       "project":
       { 
          "key": "SUITE"
       },
       "summary": `[iOS] Slardar(${crash_type}) ${jiraTitle}`,
       "description": description,
       "issuetype": {
          "name": "Bug",
       },
       "customfield_11215":[{"value" : "VideoConference"}],
       "customfield_11211":[{"value" : stack}]
   }
  }
  
  const res = await jira.issue.createIssue(data)
  await addAttachment({
    issueKey:res.key,
    aid:aid,
    crash_type:crash_type,
    issue_id: issue_id})
  return res
}

async function queryJira(params,context){
 
  var issue_id = params.issue_id
  let res = await jira.search.search({
    jql: `project = SUITE AND description ~ ${issue_id} AND resolution = Unresolved`
  })
  if(res.total>0){
    return res.issues[0].key
  }else{
    return false
  }
}

async function createDescription(params){
  let crash_type = params.crash_type
  let aid = Number(params.aid)
  let issue_id = params.issue_id
  var today = Math.floor((new Date()).getTime()/1000)
  var url_params = {start_time:today - 30*24*60*60,end_time:today}

  var description = `slardar链接：https://slardar.bytedance.net/node/app_detail/?aid=${aid}&os=iOS&region=cn#/abnormal/detail/${crash_type}/${issue_id}?params=${JSON.stringify(url_params)}\n`
  description = description + `issue_id: ${issue_id}\n`
  const versionRes = await getAppVersion({
    aid:aid,
    crash_type:crash_type,
    issue_id: issue_id,
  })
  let appVersions = versionRes.detail
  for(let i in appVersions){
    description = description + `版本：${appVersions[i].field},发生次数:${appVersions[i].count}\n`
  }
  
  const eventRes = await queryEvent({
    aid:aid,
    crash_type:crash_type,
    issue_id: issue_id,
  })
  description = description + "{code:java}\n"
  //crash的栈
  let event = eventRes.result[0].event_detail.main_thread
  description = description + `${event.reason}\n${event.thread_name}\n`
  for(let i in event.backtrace){
    let bracktrace = event.backtrace[i]
    description = description + `${i}\t${bracktrace.unit}\t${bracktrace.method}\n`
  }
  description = description + "{code}"
  return description
}

function getStack(name){
  if(name.toLowerCase().search("rtcenginekit")!=-1){
    return "Media"
  }else{
    return "iOS"
  }
}

async function addAttachment(params,callback){
  let {issueKey,aid,crash_type,issue_id} = params
  const eventRes = await queryEvent({
    aid:aid,
    crash_type:crash_type,
    issue_id: issue_id,
  })
  let event = eventRes.result[0]
  let {device_id,event_id,crash_time} = event

  const log = await downloadLog({
    device_id:device_id,
    event_id:event_id,
    crash_time:crash_time,
    aid:aid
  })

  let fileContent = log.body.Msg
  let fileName = `${aid}_${device_id}_${crash_time}_${event_id}_symbolicate`
  
  var string2fileStream = require('string-to-file-stream')
  var headers = {
    charset: 'utf-8',
    'X-Atlassian-Token': 'nocheck'
  }
  
  var options = {
    uri: jira.buildURL('/issue/' + issueKey + '/attachments'),
    method: 'POST',
    json: true,
    followAllRedirects: true,
    headers: headers,
    formData: {
        file: string2fileStream(fileContent, { path: `./${fileName}.txt` })
    }
  };
  return jira.makeRequest(options, callback);
}

module.exports.createJira = createJira
module.exports.queryJira = queryJira