/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */

const FIDB = larkcloud.db.table('FeedbackInfo')
const WADB = larkcloud.db.table('WaitAnalysis')
const ALDB = larkcloud.db.table('AutoLabels')
const db = larkcloud.db.table('LogInfo')
const { client } = require('./OpenAPIClient');
const newFeedback = require('./newFeedback')


module.exports = async function(params) {
  const ID = params.ID
  const personItems = await WADB.where({"RoomID": ID}).find();
  const logItems = await db.where({"roomID": ID}).find()
  var flag = false

  if(!logItems||logItems.length==0)
    return
  for(let i in logItems){
    let logItem = logItems[i]
    if(!logItem.addStyle||logItem.addStyle=="auto"){
      await newFeedback({"ID":ID})
      return
    }
  }

  //divice_id: room_id 多个人在一个群里查询一个会，只在群里发一次
  var groupItem = {"0":[]}
  var chat_id,open_message_id
  for(let i in personItems){
    let personItem = personItems[i]
    //如果查询了某个设备
    if(personItem.device_id){
      let device_id = personItem.device_id
      console.log(personItem.RoomID)
      console.log(device_id)
      let logItem = await db.where({roomID:personItem.RoomID,deviceID:device_id}).findOne()
      if(!logItem)
        continue
      if(logItem.diagnoseStatus!=2)
        continue
      await sendToPeople(personItem.open_id,personItem.RoomID,device_id)

      if(personItem.chat_type == "group"){
        chat_id = personItem.chat_id
        open_message_id = personItem.open_message_id
        if(groupItem[device_id]){
          groupItem[device_id].push(personItem.open_id)
        }else{
          groupItem[device_id] = [personItem.open_id]
        }
      }
      await WADB.delete(personItem)
    }else{
      var flag = true
      let feedInfo = await FIDB.where({"RoomID": ID}).sort({updatedAt: -1}).findOne();
      //当前已经有结果
      if(!feedInfo.labels||feedInfo.labels.length<=0){
        for(let j in logItems){
          //如果没诊断完的话
          if(!logItems[j].diagnoseStatus||logItems[j].diagnoseStatus!=2){
            flag = false
            break
          }
        }
      }
      if(flag){
        await sendToPeople(personItem.open_id,personItem.RoomID)
        if(personItem.chat_type == "group"){
          groupItem["0"].push(personItem.open_id)
          chat_id = personItem.chat_id
          open_message_id = personItem.open_message_id
        }
        await WADB.delete(personItem)
      }
    }
  }

  for (var key in groupItem) {
    if(key == "0" && groupItem[key].length>0)
      await sendToGroup(chat_id,open_message_id,groupItem["0"],ID)
    else if(key!="0")
      await sendToGroup(chat_id,open_message_id,groupItem[key],ID,key)
  }
}

//添加诊断结果的内容
async function addContent(analyserContent,roomID,deviceID){
  analyserContent.push([ {"tag": "text","text": "meeting id: "+ roomID}])
  var labels
  var flag = true
  var items
  if(deviceID) {
    items = await db.where({deviceID:deviceID,roomID:roomID}).find()
  } else {
    items = await db.where({roomID: roomID}).find()
  }

  for(let i in items) {
    let item = items[i]
    let labelItem = await ALDB.where({deviceID:item.deviceID,roomID:roomID}).findOne()
    if(labelItem)
      labels = labelItem.labels
    else
      labels = []
    if(labels&&labels.length>0){
      flag = false
      analyserContent.push([ {"tag": "text","text": "device id: "+ item.deviceID}])
      analyserContent.push([ {"tag": "text","text": "OS:"+ item.deviceOS}])
      for(let i in labels){
        let label = labels[i]
        analyserContent.push([{"tag": "text","text": "label:"+ label}])
        const LABELDB = larkcloud.db.table('Labels')
        let transLabel = await LABELDB.where({name:label}).findOne()
        let translet = transLabel.description
        analyserContent.push([{"tag": "text","text": "翻译:"+ translet}]) 
      }
    }
  }
  if(flag) {
    if(deviceID){
      analyserContent.push([ {"tag": "text","text": "device id: "+ deviceID}])
      analyserContent.push([ {"tag": "text","text": "当前查询设备无异常"}])
    } else
      analyserContent.push([ {"tag": "text","text": "当前会议所有设备无异常"}])
  }
  analyserContent.push([ {"tag": "a","text": "自动诊断标签总结","href": "https://bytedance.feishu.cn/docs/doccnf2GN5CehEQck2LcXlC8iuc"}])
}

async function sendToPeople(open_id,roomID,deviceID){
  const c = await client()
  var analyserContent = []
  analyserContent.push([{"tag": "at","user_id": open_id}])
  await addContent(analyserContent,roomID,deviceID)
  const res = await c.post('/message/v4/send/', {
    open_id: open_id,msg_type: 'post',
      "content": {"post": {"zh_cn": { "content": analyserContent} }}
  })
  console.log(res)
}

async function sendToGroup(chat_id,open_message_id,openIDList,roomID,deviceID){
  const c = await client()
  let analyserContent = []
  for(let i in openIDList){
    analyserContent.push([ {"tag": "at","user_id": openIDList[i]}])
  }
  await addContent(analyserContent,roomID,deviceID)
  const res = await c.post('/message/v4/send/', {
    chat_id: chat_id,msg_type: 'post',root_id: open_message_id,
    "content": {"post": {"zh_cn": { "content": analyserContent} }}
  })
  console.log(res.data)
}