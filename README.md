#IM DEMO#
IM服务基于websocket，其中GZSocketChatter是对facebook的SRWebSocket的封装，也可以直接使用SRWebSocket类，使用方法基本一致[github://SocketRocket](https://github.com/facebook/SocketRocket)

###demo的大致思路###
后台建立IM提供的API，需要客户端传递token,host,port参数拼接  
* token:从项目对应的api取得  
* host和port通过http://58.68.237.198:8034/master/server.do取得  
* 用拼接好的url来实例化一个GZSocketChatter对象，实现GZSockketChatter的代理方法，可以实现收发消息等处理  
* 其中需要根据项目修改的东西有token,发送消息的格式等

##编译前的准备##
导入websocket依赖库  
* Foundation.framework  
* Security.framework  
* CFNetwork.framework  
* libicucore.tbd  

##运行##
* 点击连接
* 文字框中可以输入文字，然后发送
* 下面的label显示收到的消息