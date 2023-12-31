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
const newFeedback = require('./newFeedback')
const statistics = require('./statisticsRecord');
const sendNotice = require('./sendNotice')
const moment = require('moment');
var queryCommand
const helpText = `请输入以下命令进行查询： 括号为可选内容，参数间用空格分割 /n
查询会议: /q keyword (时间参数) /n
(其中keyword 可以是， meeting id，"u-"+user id，@需要查询的用户的形式, meeting number，邮箱前缀。后两者只在字节内部有效) /n
使用keyword不带时间参数默认查询当天会议 /n
查询当天特定时间段所有会议(StartHour- EndHour) , 如/q keyword (8-16)为查询当天8点到16点所有会议/n
查询当天时间前n天所有会议 -Nd, 如/q keyword -2d为查询前天所有会议/n
查询当天时间前n天指定时间段会议 -Nd(StartHour- EndHour), 如/q keyword -1d(15-16)为查询昨天15点到16点所有会议/n
查询指定日期当天所有会议: YYYY-MM-DD如/q keyword 2020-01-02/n
使用会议号查询建议添加日期，否则可能会查询到会议号相同的其他会议 /n
查询网站统计信息:/s （日期YYYY-MM-DD) /n
查看帮助:/h`

module.exports = async function(event, context) {
  console.log('robot_reply',event)
  const { open_id, chat_type,chat_id, open_message_id} = event;
  var {text_without_at_bot} = event;
  queryCommand = text_without_at_bot
  var operate,orders
  //如果输入内容不为空
  if(text_without_at_bot){
    //判断以@形式查询
    if(text_without_at_bot.search("<at")!=-1){
      console.log('robot_reply',"以@方式查询")
      var at_id = text_without_at_bot.split("user_id=\"")[1]
      at_id = at_id.split("\"")[0]
      text_without_at_bot = text_without_at_bot.replace(/<at.*at>/,"u-"+at_id)
      console.log('robot_reply',text_without_at_bot)
    }
    orders = text_without_at_bot.trim().split(" ")
    operate = orders[0]
  }else{
    operate = "/h"
  }
  switch(operate) {
    case "/q":
      const keyword = orders[1]
      var vagueData
      var today = new Date(moment(new Date()).format('YYYY-MM-DD')).getTime()
       // /q XXX -d(1-20) 或者 /1 XXX (1-20)
      if(orders.length == 3){
        var str_format = orders[2]
        if(str_format.search(/[(]/)!=-1){
          if(str_format.search("d")!=-1){
            var number = Number(str_format.split("d")[0].split("-")[1])
            today = today - number*24*60*60*1000
          }
          var caculate = str_format.split("(")[1].split(")")[0]
          var second = Number(caculate.split("-")[1])
          var first = Number(caculate.split("-")[0])
          today = today + first*60*60*1000
          vagueData = await getVagueData(keyword,today,second-first)
        // /q XXX -1d
        }else if(str_format.search("-")==0){
          if(str_format.search("d")!=-1){
            var number = Number(str_format.split("d")[0].split("-")[1])
            today = today - number*24*60*60*1000
          }
          vagueData = await getVagueData(keyword,today)
        } 
        else{ // /q XXX 2020-03-22
          vagueData = await getVagueData(keyword,getTime(orders[2]))
        }
      }else if(orders.length == 4){ // /q XXX 2020-03-22 2或者/q XXX 2020-03-22 2020-03-25
        let first = getTime(orders[2])
         if(orders[3].search("-")!=-1){
           let num = (getTime(orders[3]) - first)/1000/60/60
           vagueData = await getVagueData(keyword,first,num)
         }else{
            vagueData = await getVagueData(keyword,first,orders[3])
         }
      }else{
        vagueData = await getVagueData(keyword)
      }
      if(vagueData.success) { //模糊查询有数据
        const data = vagueData.data.Data
        if(Array.prototype.isPrototypeOf(data)) {  //多个会议
          sendLongListMeeting(data,open_id,chat_id,open_message_id,chat_type)
        }else{ //单个会议
          await sendSingleMeeting(data,open_id,chat_id,open_message_id,keyword,chat_type)
        }
      }else{//没有对应结果
        const request = await client()
         await request.post('/message/v4/send/',{
          "chat_id":chat_id,"open_id":open_id,"root_id":open_message_id,"msg_type":"text",
          "content":{
            "text": `<at user_id="${open_id}"></at> 无法查询到结果\n`+helpText,
            }
        })
      }
      break
    case "/s":
      if(orders.length==2){// /s 2020-02-22
        var date = orders[1]
        date = date.trim();
        await queryStatisticsData(open_id,chat_id,open_message_id,getStaticTime(date))
      }else if(orders.length==3){
        let date1 = new Date(orders[1])
        var date2
        if(orders[2].search("-")!=-1)
          date2 = new Date(orders[2])
        else
          date2 = new Date(date1.getTime()+(Number(orders[2])-1)*24*60*60*1000)
         await queryStatisticsData(open_id,chat_id,open_message_id,
         {"date1":date1,"date2":date2})
      }else{
        await queryStatisticsData(open_id,chat_id,open_message_id)
      }
      break
    default:
      const c = await client()
      await c.post('/message/v4/send/',{
      "chat_id":chat_id,"root_id":open_message_id,"msg_type":"text",
      "content":{
        "text": `<at user_id="${open_id}"></at> ${helpText}`,
        }
      })
  }
}

//查询统计数据
async function queryStatisticsData(open_id,chat_id,open_message_id,date) {
  var result = await statistics(date);
  console.log(result)
  const c = await client()
  await c.post('/message/v4/send/',{
    "chat_id":chat_id,"open_id":open_id,"root_id":open_message_id,"msg_type":"text",
    "content":{
      "text": `<at user_id="${open_id}"></at> ${result}`,
      }
  })
}

//发送单个会议，富文本
async function sendSingleMeeting(meetingData,open_id,chat_id,open_message_id,keyword,chat_type,secondSend){
  const MIDB = bc.db.table('MeetingInfo')
  const WADB = larkcloud.db.table('WaitAnalysis')
  let {ID,StartTime,EndTime} = meetingData
  var info = await MIDB.where({"ID": ID}).sort({updatedAt: -1}).findOne();
  const c = await client()
  if(!info) { //没有缓存，需要手动添加
    if(!secondSend){ //首次发送该会议
      await c.post('/message/v4/send/',{
        "chat_id":chat_id,"root_id":open_message_id,"msg_type":"text",
        "content":{
          "text": `<at user_id="${open_id}"></at> 暂无缓存，数据获取中`,
          }
      })
      let typeRes = await axios.get(`https://internal-api.feishu.cn/view/log_upload/api/v1/meeting?id=${ID}`)
      let feedbackType = typeRes.data.data.meeting_type
      var feedbackTypeString
      if(feedbackType == 1)
        feedbackTypeString = "VC 1v1"
      else
        feedbackTypeString = "VC Group Meeting"
      await newFeedback({"type":feedbackTypeString,"ID":ID})
      //记录信息
      let waitItem =  await WADB.where({"RoomID": ID,"open_id":open_id}).findOne();
      if(!waitItem){
        let personItem = WADB.create({RoomID:ID,open_id: open_id,chat_id:chat_id, open_message_id:open_message_id,chat_type:chat_type});
        await WADB.save(personItem);
      }
    }
    var sleep = require('sleep');
    sleep.sleep(3)
    sendSingleMeeting(meetingData,open_id,chat_id,open_message_id,keyword,chat_type,true)
  }else{ //查询数据
    let {Status,VendorType,ParticipantNum,VcType} = info
    const statusString = getStatusString(Status)
    const vctypeString = getVcTypeString(VcType)
    const vendorTypeString = getVendorTypeString(VendorType)
    let content = []
    content.push([ {"tag": "at","user_id": open_id}])
    content.push([ {"tag": "text","text": "会议ID: "+ID}])
    content.push([ {"tag": "text","text": "开始时间: "+StartTime}])
    content.push([ {"tag": "text","text": "结束时间: "+EndTime}])
    content.push([ {"tag": "text","text": "会议类型: "+ vctypeString}])
    content.push([ {"tag": "text","text": "会议子类型: "+ vendorTypeString}])
    content.push([ {"tag": "text","text": "会议状态: "+ statusString}])
    let startFormat = moment(new Date(StartTime)).format('YYYYMMDDHHmmss')
    let endFormat = moment(new Date(EndTime)).format('YYYYMMDDHHmmss')
    var appType = 1
    if(info.Type == 1)
      appType = 0
    content.push([ {"tag": "a","text": "会议详情","href": "https://meeting-devops.bytedance.net/?state=&code=618878132c39137b58362ac3b6e1e7c7df721c3d#/vc-feedback/feedbackDetail/"+ID}])
    content.push([{"tag": "a","text": "RTC详情","href":`https://meeting-devops.bytedance.net/?state=&code=4392cd82dc4ba1a3400a89c40f0c3b6a1275687e#/analytics/view?startTime=${startFormat}&endTime=${endFormat}&roomId=${ID}&appType=${appType}`}])
    content.push([{"tag": "a","text": "诊断","href": `https://meeting-devops.bytedance.net/?state=&code=b2915ff3eab863c51008f0e846e9ccf6cd98e8a2#/analytics/view?roomId=${ID}&startTime=${startFormat}&endTime=${endFormat}&appType=${appType}`}])
    content.push([{"tag": "a","text": "服务端日志","href":"http://room.byted.org/?key="+keyword+"&start="+info.StartTime+"&end="+info.EndTime+"&env=online&unit=cn"}
    ])
    const res = await c.post('/message/v4/send/', {
      chat_id: chat_id,open_id:open_id,msg_type: 'post',root_id: open_message_id,
      "content": {"post": {"zh_cn": { "content": content} } } 
    })
    console.log('robot_reply',res)

    //把这次查询加入到等待发送诊断通知的表中
    let waitItem =  await WADB.where({"RoomID": ID,"open_id":open_id}).findOne();
    if(!waitItem){
    let personItem = WADB.create({RoomID:ID,open_id: open_id,chat_id:chat_id, open_message_id:open_message_id,chat_type:chat_type});
      await WADB.save(personItem);
    }
    sendNotice({"ID":ID})
  }
}

//多个会议长列表
async function sendMultMeeting(meetingDatas,open_id,chat_id,open_message_id,chat_type){
  let divs = []
  divs.push({"tag": "div","text": {"tag": "lark_md",
          "content": `<at id="${open_id}"></at>`}})
  meetingDatas.forEach(function(meet,i){
    let {ID,StartTime,MeetingType,EndTime,Status} = meet
    console.log(Status)
    var deviceId = Status.split("(")[1].split(")")[0]
    if(deviceId == '0'){
      let arr = Status.match(/[(]\d+[)]/g)
      if(arr.length>1)
        deviceId = arr[1].split("(")[1].split(")")[0]
    }
      
    divs.push({
        "tag": "div",
        "text": {
          "tag": "lark_md",
          "content": "会议ID: "+ID +"\n开始时间: "+ StartTime + "\n结束时间: " + EndTime + "\n会议类型: " + MeetingType + "\n设备ID: " + deviceId
        },
        "extra": {
            "tag": "button",
            "text": {"tag": "lark_md","content": "详情"},
            "type": "default","value": {"ID":ID,"chat_id":chat_id,"chat_type":chat_type,device_id:deviceId}
        }
    })
  })
  const c = await client()
  await c.post('/message/v4/send/', {
    chat_id: chat_id,open_id:open_id,msg_type: 'interactive',
    root_id: open_message_id,"update_multi":false,
    "card": {"config": { "wide_screen_mode": false},
        "elements": divs }
  });
}

//多个会议可选择列表，会议选择卡片
async function sendLongListMeeting(meetingDatas,open_id,chat_id,open_message_id,chat_type){
  let divs = []
  let meet = meetingDatas[0]
  let defaultStr = "请选择会议时间段"
  let options = []
  let ID_array = []
  let time_array = []
  let {ID,StartTime,MeetingType,EndTime,Status} = meet  
  var deviceId = ""
  if(Status.split("(").length>1)
    deviceId = Status.split("(")[1].split(")")[0]
  if(deviceId == '0'){
    let arr = Status.match(/[(]\d+[)]/g)
    if(arr.length>1)
      deviceId = arr[1].split("(")[1].split(")")[0]
  }

  for(let i in meetingDatas){
    let option = getFormatOption(meetingDatas[i].StartTime,meetingDatas[i].EndTime)
    options.push({
      "text": {
          "tag": "plain_text",
          "content": option
      },
      "value": option
    })
    time_array.push(option)
    ID_array.push(meetingDatas[i].ID)
  }
  let select_menu = {
     "tag": "select_static",
     "placeholder": {
         "tag": "plain_text",
         "content": defaultStr
     },
     "value":{
       "array":ID_array,
       "time_array":time_array,
       "chat_id":chat_id,
       "chat_type":chat_type,
       "device_id":deviceId,
       "queryCommand":queryCommand
     },
     "options": options
  }

  divs.push({"tag": "div","text": {"tag": "lark_md",
          "content": `<at id="${open_id}"></at>\n`+queryCommand},"extra":select_menu})      
  divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": defaultStr
      }})
  
  const c = await client()
  const res = await c.post('/message/v4/send/', {
    chat_id: chat_id,open_id:open_id,msg_type: 'interactive',
    root_id: open_message_id,"update_multi":false,
    "card": {"config": { "wide_screen_mode": false},
        "elements": divs }
  });
  console.log(res)
}

//从接口查询会议信息
async function getVagueData(keyword,firstDay,time) {
  keyword = keyword + ""
  var flag = false
  if(keyword.search("u-") != -1){
    keyword = keyword.split("u-")[1]
    flag = true
  }
  if(keyword.length<19)
    flag = true
  var url = "https://ee.bytedance.net/view-internal/realtime_log/api/v1/log?Env=online&Keyword=" + keyword
  if(flag){
    if(!firstDay)
      firstDay = new Date(moment(new Date()).format('YYYY-MM-DD')).getTime()
    firstDay = firstDay - 8*60*60*1000
    var secondDay
    if(!time)
      secondDay = firstDay + 24*60*60*1000
    else
      secondDay = firstDay + Number(time)*60*60*1000
    url = url + `&StartTime=${firstDay}&EndTime=${secondDay}`
  }
  console.log('robot_reply',url)
  const response = await axios.get(url)
  return response.data
}

function getStatusString(Status){
  switch(Status) {
  case 0:
    return "UNKNOWN"
  case 1:
    return "CALLING"
  case 2:
    return "ON_THE_CALL"
  case 3:
    return "END"
  }
}

function getVendorTypeString(VendorType){
  switch(VendorType) {
  case 0:
    return "ZoomMeeting"
  case 1:
    return "RTCMeeting"
  case 2:
    return "LarkRTCMeeting"
  case 3:
    return "LarkPreRTCMeeting"
  }
}

function getVcTypeString(VcType){
  if(VcType == 1)
    return "1v1 通话"
  else
    return "多人视频会议"
}

function getTime(str_time){
  if(str_time.search("-")!=-1)
    return (new Date(str_time)).getTime()
  str_time = str_time.trim()
  const today = new Date() 
  var year = today.getFullYear()
  var month = today.getMonth()+1
  var day = today.getDate()

  if(str_time.search("年")!=-1){
    year = str_time.split("年")[0]
    str_time = str_time.split("年")[1]
  }

  if(str_time.search("月")!=-1){
    month = Number(str_time.split("月")[0])
    str_time = str_time.split("月")[1]
  }

  if(str_time.search("日")!=-1){
    day = Number(str_time.split("日")[0])
    str_time = str_time.split("日")[1]
  }

  if(month<10)
    month = "0" + month
  if(day<10)
    day = "0" +day
  
  var res = `${year}-${month}-${day}`
  var time = new Date(res).getTime()
  if(str_time.search("点")!=-1){
    let hour = Number(str_time.split("点")[0])
    time = time + hour*60*60*1000
  }
  return time
}

function getStaticTime(str_format){
  var today = new Date(moment(new Date()).format('YYYY-MM-DD')).getTime()
  if(str_format.search(/[(]/)!=-1){
    if(str_format.search("d")!=-1){
      var number = Number(str_format.split("d")[0].split("-")[1])
      today = today - number*24*60*60*1000
    }
    var caculate = str_format.split("(")[1].split(")")[0]
    var second = Number(caculate.split("-")[1])
    var first = Number(caculate.split("-")[0])
    return {
      "date1":new Date(today+ first*60*60*1000),
      "date2":new Date(today+ second*60*60*1000)
    }
  }else if(str_format.search("-")==0){
    if(str_format.search("d")!=-1){
      var number = Number(str_format.split("d")[0].split("-")[1])
      today = today - number*24*60*60*1000
    }
    return {
    "date1":new Date(today)
    }
  }else{
    return {
      "date1":new Date(str_format)
    }
  }
     
}

function getFormatOption(startTime,endTime){
  return moment(new Date(startTime)).format("MM-DD HH:mm:ss") + " - " +
  moment(new Date(endTime)).format("HH:mm:ss")
}

module.exports.getVagueData = getVagueData