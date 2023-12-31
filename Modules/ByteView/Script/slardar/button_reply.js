/**
  * @param params 调用参数，HTTP 请求下为请求体
  * @param context 调用上下文
  *
  * @return 函数的返回数据，HTTP 场景下会作为 Response Body
  *
  * 完整信息可参考：
  * https://larkcloud.bytedance.net/docs/cloud-function/basic.html
  */

const {queryJira,createJira} = require("./Jira")
const { client } = require('./OpenAPIClient');


module.exports = async function(params, context) {

  
  const c = await client()
  let {open_id,open_message_id,action} = params
  let value = action.value
  let {chat_id,aid,crash_type,issue_id,event_detail} = value
  var key = await queryJira({issue_id:issue_id})
  if(key){
    await c.post('/message/v4/send/',{
      "chat_id":chat_id,"open_id":open_id,"root_id":open_message_id,"msg_type":"text",
      "content":{
        "text": `<at user_id="${open_id}"></at> jira已创建:https://jira.bytedance.com/browse/${key}`,
        }
    })
  }else{
    const res = await createJira({aid:aid,issue_id:issue_id,crash_type:crash_type})
    if(res.key){
      await c.post('/message/v4/send/',{
        "chat_id":chat_id,"open_id":open_id,"root_id":open_message_id,"msg_type":"text",
        "content":{
         "text": `<at user_id="${open_id}"></at> jira创建成功:https://jira.bytedance.com/browse/${res.key}`
        }
      })
    }else{
      await c.post('/message/v4/send/',{
        "chat_id":chat_id,"open_id":open_id,"root_id":open_message_id,"msg_type":"text",
        "content":{
         "text": `<at user_id="${open_id}"></at> jira创建失败`
        }
      })
    }
  }
}