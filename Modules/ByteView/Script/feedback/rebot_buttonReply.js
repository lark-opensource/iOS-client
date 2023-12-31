/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */
module.exports = async function(params, context) {
  const reply = require('./robot_reply');
  if(params.action.option){ //会议选择卡片改变选项
    let {array,chat_id,chat_type,device_id,time_array,queryCommand} = params.action.value
    let option = params.action.option
    let index = time_array.indexOf(option)
    let ID = array[index]
    let {getVagueData} = require("./robot_reply")
    let res = await getVagueData(ID)
    let meet = res.data.Data
    console.log(meet)
    //会议选择卡片
    let divs = []
    let options = []
    for(let i in array){
      options.push({
        "text": {
            "tag": "plain_text",
            "content": time_array[i]
        },
        "value": time_array[i]
    })
  }
  let select_menu = {
     "tag": "select_static",
     "placeholder": {
         "tag": "plain_text",
         "content": option
     },
     "value":{
       "array":array,
       "time_array":time_array,
       "chat_id":chat_id,
       "chat_type":chat_type,
       "device_id":device_id,
       "queryCommand":queryCommand
     },
     "options": options
  }
    divs.push({"tag": "div","text": {"tag": "lark_md",
          "content": `<at id="${params.open_id}"></at>\n`+queryCommand},"extra":select_menu})

    let {StartTime,EndTime} = meet
    let MeetingType = await getMeetType(ID)
    divs.push({
      "tag": "div",
      "text": {
        "tag": "lark_md",
        "content": "会议ID: "+ID +"\n开始时间: "+ StartTime + "\n结束时间: " + EndTime + "\n会议类型: " + MeetingType + "\n设备ID: " + device_id
      },
      "extra": {
          "tag": "button",
          "text": {"tag": "lark_md","content": "详情"},
          "type": "default","value": {"ID":ID,"chat_id":chat_id,"chat_type":chat_type,device_id:device_id}
      }
    })
    return {"config": { "wide_screen_mode": false},"elements": divs }
  }else{ //点击详情
    await reply({
      "open_id":params.open_id, 
      "chat_id":params.action.value.chat_id, 
      "open_message_id": params.open_message_id,
      "text_without_at_bot":"/q " + params.action.value.ID,
      "chat_type":params.action.value.chat_type
    })
    const WADB = larkcloud.db.table('WaitAnalysis')
    let waitItem =  await WADB.where({"RoomID": params.action.value.ID,"open_id":params.open_id}).findOne();
    if(waitItem){
      waitItem.device_id = params.action.value.device_id
      await WADB.save(waitItem);
    }
  }
}

async function getMeetType(ID){
  let typeRes = await axios.get(`https://internal-api.feishu.cn/view/log_upload/api/v1/meeting?id=${ID}`)
  let feedbackType = typeRes.data.data.meeting_type
  if(feedbackType == 1)
    return "1v1通话"
  else
    return "多人会议"
}