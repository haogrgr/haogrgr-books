Netty In Action
===







源码笔记:

NioEventLoop里面有select循环

1.服务端

服务端启动的时候, ServerBootstrap调用doBind方法, 初始化Channel, 并注册accept事件.

当accept发生的时候, 会调用NioEventLoop.processSelectedKey(SelectionKey, AbstractNioChannel)方法初始select结果, 这个时候SelectionKey.attachment就是NioServerSocketChannel, 

然后调用该channel.unsafe().的read方法, 具体的unsafe类型是io.netty.channel.nio.AbstractNioMessageChannel.newUnsafe()NioMessageUnsafe

NioMessageUnsafe.read方法内部调用NioServerSocketChannel.doReadMessages方法. 这个方法内部调用底层channel的accept方法, 然后将新的NioSocketChannel加入到参数中, 

然后触发pipline的fireChannelRead方法, 这个时候, ServerBootstrap.init中注册ServerBootstrapAcceptor.channelRead方法被触发, 

进而在该方法中, 给收到的channel的pipline中加入我们启动时设置的ChannelHandler(bootstrap.childHandler)

然后关联channel和EventLoop(这里是childGroup), 并注册selector, 获取selectionKey, 

后续就是select得到某些事件, 然后调用对应的pipline, 并依次调用channelHandler

而且各种事件都是在eventloop里面执行的, 


2. 客户端

调用Bootstrap的connect方法初始化, channel的初始化类似于serverChannel, 只是注册的不是accept事件, 而是read事件
对应的unsafe为NioSocketChannelUnsafe

然后调用Bootstrap.init(Channel) 方法将, 我们的bootstrap.handler添加到channel的pipline上去.

当读发生的时候,  调用unsafe的read方法AbstractNioByteChannel.NioByteUnsafe.read()

内部大概是读数据, 然后触发pipline的read, 将读到的数据交给我们的handler处理.


Server端BossGroup负责accept, childGroup负责具体链接的读写.
当有多个ServerBootstrap的时候, 可以设置BossGroup线程为多个,默认是核数, 不过没关系, 只有真实需要的时候, 才会启动多余的线程, 所以初始值大些没关系.


tips:

通过ChannelOutboundBuffer来缓冲write的对象, 写的时候就可以成批的写了, 并且当写缓冲区满了的时候, 就注册op_write事件, 等待底层缓冲区有空间, 当可以写了后, select处理会再次触发写ChannelOutboundBuffer缓冲的数据, 写完就取消注册op_write事件

为啥取消注册op_write这里有写
http://blog.csdn.net/zhouhl_cn/article/details/6582435

写就绪相对有一点特殊，一般来说，你不应该注册写事件。写操作的就绪条件为底层缓冲区有空闲空间，而写缓冲区绝大部分时间都是有空闲空间的，所以当你注册写事件后，写操作一直是就绪的，选择处理线程全占用整个CPU资源。所以，只有当你确实有数据要写时再注册写操作，并在写完以后马上取消注册。

当有数据在写时，将数据写到缓冲区中，并注册写事件。
public void write(byte[] data) throws IOException {  
    writeBuffer.put(data);  
    key.interestOps(SelectionKey.OP_WRITE);  
}  

注册写事件后，写操作就绪，这时将之前写入缓冲区的数据写入通道，并取消注册。
channel.write(writeBuffer);  
key.interestOps(key.interestOps() & ~SelectionKey.OP_WRITE);  

