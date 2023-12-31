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
const {addJiraContent,queryNeo} = require("./sladar_notice")

module.exports = async function(params, context) {
  const db = larkcloud.db.table('slardar')
  let items = await db.where({"product":"checkboard"}).find()
  for(let i in items){
    let item = items[i]
    await sendNotice("crash",item.chat_id)
    await sendNotice("watch_dog",item.chat_id)
    await sendNew("crash", item.chat_id)
    await sendNew("watch_dog", item.chat_id)
  }
}

async function sendNew(crash_type,chat_id){
  let aid = 2584
  var today = Math.floor((new Date()).getTime()/1000)
  let queryData = {aid:aid,crash_type:crash_type,managers:[],start_time:today-24*60*60}
  console.log(queryData)
  var queryResults = await querySlardar(queryData)
  console.log("queryResults:",queryResults)
   var divs = []
  let c = await client()
  divs.push({"tag": "div","text": {"tag": "lark_md",
      "content": moment(new Date()).format('YYYY-MM-DD')}})
  await addContent(divs,aid,crash_type,chat_id,queryResults,true)
  await c.post('/message/v4/send/', {
    chat_id: chat_id,msg_type: 'interactive',"update_multi":false,
    "card": {"config": { "wide_screen_mode": true},
        "elements": divs }
  });
}

async function sendNotice(crash_type,chat_id){
  var aid = 2584
  let c = await client()
  var divs = []
  
  divs.push({"tag": "div","text": {"tag": "lark_md",
      "content": moment(new Date()).format('YYYY-MM-DD')}})
  divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": `checkboard ${crash_type} summary`
      }
  })
  let queryResults = await queryNeo(aid,crash_type,chat_id)
  let total = queryResults.total
  await addContent(divs,aid,crash_type,chat_id,queryResults)
  if(queryResults.total>10){
    var pgno = 2
    while(pgno*10<queryResults.total){
      let results =  queryNeo(divs,aid,crash_type,chat_id,pgno)
      await addContent(divs,aid,crash_type,chat_id,queryResults)
      pgno = pgno + 1
    }
  }
  divs.push({"tag": "hr"})
  await c.post('/message/v4/send/', {
    chat_id: chat_id,msg_type: 'interactive',"update_multi":false,
    "card": {"config": { "wide_screen_mode": true},
        "elements": divs }
  });
}

async function addContent(divs,aid,crash_type,chat_id,queryResults,isAdd) {  
  let total = queryResults.total
  addTitle(divs,crash_type,total,isAdd)
  if(total>0) {
    let result = queryResults.result
    var crashList = []
    var index = 0

    var today = Math.floor((new Date()).getTime()/1000)
    var start_time = today - 30*24*60*60
    if(isAdd)
      start_time = today - 24*60*60
    var url_params = {start_time:start_time,end_time:today}
    for(let i in result){
      let crash = result[i]
      let url = `https://slardar.bytedance.net/node/app_detail/?aid=${aid}&os=iOS&region=cn#/abnormal/detail/${crash_type}/${crash.issue_id}?params=${JSON.stringify(url_params)}`
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
     divs.push.apply(divs,crashList)
  }
}

async function addTitle(divs,crash_type,total,isAdd){
  if(isAdd){
    divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": `${crash_type} : ${total} (今日新增)`
      }
    })
  }else{
    divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": `${crash_type} : ${total} (最近30天)`
      }
    })
  }
  
}