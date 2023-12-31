/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */
const db = larkcloud.db.table('slardar')
const {addContent,getQueryResults} = require('./sladar_notice')
const { client } = require('./OpenAPIClient');
const helpText = `首次使用请使用需要进行配置/s [起始版本，中止版本] 进行配置\n例如：/s [3.17,3.19]\n,使用/s neo配置neo通知\n输入/q lark inhouse/AppStore/overseas [起始版本，中止版本] crash/watch_dog进行查询\n例如：/q lark inhouse [3.17,3.18] crash`
module.exports = async function(event, text) {
  const { open_id, chat_type,chat_id, open_message_id,text_without_at_bot} = event;
  let c = await client()
  var operate,orders
  if(text_without_at_bot){
    orders = text_without_at_bot.trim().split(" ")
    operate = orders[0]
  }else{
    operate = "/h"
  }

  var item = await db.where({chat_id:chat_id}).findOne()

  switch(operate){
    case "/q":
      if(!item)
        item = await db.where().findOne()
      let name = orders[1].trim()
      let version = orders[2].trim()
      let editions = orders[3].trim()
      let crash_type = orders[4].toLowerCase().trim()
      let aid = getAid(name,version)

      let divs = []
      divs.push({"tag": "div","text": {"tag": "lark_md",
          "content": `<at id="${open_id}"></at>`}})
      
      let editionArray = getEditionArray(editions)

      for(let i in editionArray){
        divs.push({
          "tag": "div",
          "text": {
            "tag": "lark_md",
            "content": editionArray[i] + " " + name + " "+ version + " summary"
          }
        })
        let queryResults = await getQueryResults(aid,crash_type,chat_id,editionArray[i])
        await addContent(divs,aid,crash_type,chat_id,queryResults)
        divs.push({"tag": "hr"})
      }
      const res = await c.post('/message/v4/send/', {
        chat_id: chat_id,open_id:open_id,msg_type: 'interactive',
        root_id: open_message_id,"update_multi":false,
        "card": {"config": { "wide_screen_mode": false},
            "elements": divs }
      });
      console.log(res)
      break
    case "/s":
      var item
      let editions_str = orders[1].trim()
      if(editions_str.search(/\[/)==-1){
        let product = editions_str.trim().toLowerCase()
        item = await db.where({chat_id:chat_id,product:product}).findOne()
        if(!item){
          item = await db.create({chat_id:chat_id,product:product})
          await db.save(item)
        }
      }else{
        let setEditions = getEditionArray(editions_str)
        var manager
        if(orders.length>2)
          manager = orders[2].trim()
        item = await db.where({chat_id:chat_id,product:"lark"}).findOne()
        if(!item){
          let newItem = await db.create({chat_id:chat_id,editions:setEditions,manager:manager})
          await db.save(newItem)
        }else{
          item.editions = setEditions
           if(manager)
            item.manager = manager
            await db.save(item)
        }
      }
      await c.post('/message/v4/send/',{
        "chat_id":chat_id,"root_id":open_message_id,"msg_type":"text",
        "content":{
          "text": `<at user_id="${open_id}"></at> 配置更新完成`,
          }
      })
      break
    default:
      await c.post('/message/v4/send/',{
        "chat_id":chat_id,"root_id":open_message_id,"msg_type":"text",
        "content":{
          "text": `<at user_id="${open_id}"></at> ${helpText}`,
          }
      })
      return
  }

}

function getAid(name,version) {
  if(name.toLowerCase()=="neo")
    return 2848
  if(version.toLowerCase() == "inhouse")
    return 1161
  else if(version.toLowerCase() == "appstore")
    return 1378
  else
    return 1664
}

function getEditionArray(editions){
  var array = []
  let edition_str = editions.substring(1,editions.length-1)
  let first = edition_str.split(",")[0]
  let second = edition_str.split(",")[1]

  let bigEdition= first.split(".")[0]
  let firstSonEdition = Number(first.split(".")[1])
  let secondSonEdition = Number(second.split(".")[1])

  for(var i=firstSonEdition;i<=secondSonEdition;i++){
    array.push(bigEdition + "." + i)
  }
  
  return array
}