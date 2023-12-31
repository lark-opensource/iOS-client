/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */
const { client } = require('./OpenAPIClient');
const querySlardar = require('./querySlardar')
const moment = require('moment');
var issueArray = []
const db = larkcloud.db.table('slardar')
const {queryJira} = require("./Jira")
module.exports = async function(params, context) {
  
  let items = await db.where().find()
  let c = await client()
  for(let i in items){
    let item = items[i]
    for(let j in item.editions){
      var divs = []
      divs.push({"tag": "div","text": {"tag": "lark_md",
          "content": moment(new Date()).format('YYYY-MM-DD')}})
      await addChildNotice(divs,1161,item.editions[j],item.chat_id) 
      await addChildNotice(divs,1378,item.editions[j],item.chat_id) 
      await addChildNotice(divs,1664,item.editions[j],item.chat_id) 
      await c.post('/message/v4/send/', {
        chat_id: item.chat_id,msg_type: 'interactive',"update_multi":false,
        "card": {"config": { "wide_screen_mode": true},
            "elements": divs }
      });
    }
  }
}

async function addChildNotice(divs,aid,edition,chat_id){
    //标题
  let crashResult = await getQueryResults(aid,"crash",chat_id,edition)
  let watchDogResult = await getQueryResults(aid,"watch_dog",chat_id,edition)
  let title = edition + " "+ getAidString(aid) + " summary"
  let secondLine = ""
  if(crashResult.total == 0)
    secondLine = secondLine + " crash: 0"
  if(watchDogResult.total == 0)
    secondLine = secondLine + " watch_dog: 0"

  divs.push({
    "tag": "div",
    "text": {
      "tag": "lark_md",
      "content": title
    }
  })
  if(secondLine!=""){
    divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": secondLine
      }
    })
  }

  await addContent(divs,aid,"crash",chat_id,crashResult)
  await addContent(divs,aid,"watch_dog",chat_id,watchDogResult)
  divs.push({"tag": "hr"})
}


async function getQueryResults(aid,crash_type,chat_id,edition) {
  let queryData = {aid:aid,crash_type:crash_type}
  if(edition){
    let sub_conditions = [{type: "expression", dimension: "is_parsed", op: "eq", value: "1"},{type: "expression", dimension: "app_version", op: "gt", value: edition}]
    let array = edition.split(".")
    let sonEdition = Number(array[1])
    sub_conditions.push({type: "expression", dimension: "app_version", op: "lt", value: array[0]+"."+(sonEdition+1)})
    queryData["filters_conditions"] = {type: "and", sub_conditions:sub_conditions}
  }

  var managers = []
  let item = await db.where({chat_id:chat_id}).findOne()
  managers.push(item.manager)
  queryData["managers"] = managers  

  var queryResults = await querySlardar(queryData)
  return queryResults
}

async function addContent(divs,aid,crash_type,chat_id,queryResults) {  
  let total = queryResults.total

  if(total>0) {
    divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": `${crash_type} : ${total} (最近30天)`
      }
    })

    let result = queryResults.result
    var crashList = []
    var index = 0

    var today = Math.floor((new Date()).getTime()/1000)
    var url_params = {start_time:today - 30*24*60*60,end_time:today}
    for(let i in result){
      let crash = result[i]
      let url = `https://slardar.bytedance.net/node/app_detail/?aid=${aid}&os=iOS&region=cn#/abnormal/detail/${crash_type}/${crash.issue_id}?params=${JSON.stringify(url_params)}`
      if(crash.user>1 || crash.count>1){
        index = index + 1
        var div = {
          "tag": "div",
          "text": {
            "tag": "lark_md",
            "content": `[${index}: ${crash.event_detail.replace("[","【").replace("]","】").trim()} (${crash.count}/${crash.user})](${url})`
          }
        }
        let buttonData = {
          "aid":aid,"crash_type":crash_type,"event_detail":crash.event_detail,"chat_id":chat_id,"issue_id":crash.issue_id
        }
        await addJiraContent(crashList,div,crash.issue_id,buttonData)
      }
    }
    divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": `${crash_type} : ${index} (最近30天user>1或count>1)`
      }
    })
    divs.push.apply(divs,crashList)
  }
}

function getAidString(aid){
  switch(aid) {
    case 1378:
      return "AppStore"
    case 1161:
      return "inhouse"
    case 1664:
      return "overseas"
    case 2848:
      return "NEO"
  }
}

async function addJiraContent(crashList,div,issue_id,buttonData){
  var key = await queryJira({issue_id:issue_id})
  if(key){
    crashList.push(div)
    crashList.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": `https://jira.bytedance.com/browse/${key}`
      }
    })
  }else{
    div["extra"] = {
      "tag": "button",
      "text": {"tag": "lark_md","content": "创建jira"},
      "type": "default","value": buttonData
    }
    crashList.push(div)
  }
}

async function queryNeo(aid,crash_type,chat_id,pgno) {
  let queryData = {aid:aid,crash_type:crash_type,managers:[]}
  if(pgno){
    queryData["pgno"] = pgno
  }else{
    pgno = 1
  }
  var queryResults = await querySlardar(queryData)
  return queryResults
}

module.exports.queryNeo = queryNeo
module.exports.getQueryResults = getQueryResults
module.exports.addContent = addContent
module.exports.addJiraContent = addJiraContent