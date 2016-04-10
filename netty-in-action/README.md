#Netty In Action

		读书笔记, 以及Netty源码阅读笔记.




<br>
##1. Java BIO

<br>
####1.1 使用例子

```java
final ServerSocket socket = new ServerSocket(port);
try {
	for (;;) {
		final Socket clientSocket = socket.accept();
		System.out.println("Accepted connection from " + clientSocket);
		new Thread(new Runnable() {
			@Override
			public void run() {
				OutputStream out;
				try {
					out = clientSocket.getOutputStream();
					out.write("Hi!\r\n".getBytes(Charset.forName("UTF-8")));
					out.flush();
					clientSocket.close();
				} catch (IOException e) {
					e.printStackTrace();
				} finally {
					try {
						clientSocket.close();
					} catch (IOException ex) {
					}
				}
			}
		}).start();
	}
} catch (IOException e) {
	e.printStackTrace();
}
```

<br>
####1.2 主要问题

1. 每个客户端过来, 都需要单独的线程来处理, JVM每个线程需要64KB~1M的内存, 处理大量客户端需要大量的线程来支持.

2. 大量的线程需要更多的内存支持, 且线程数量越多, 线程上下文切换的消耗越大.

3. 大量的客户端 -> 大量的线程 -> 大量的读写 -> 大量的阻塞与唤醒 -> 内存消耗大, 上下文切换多, 线程调度慢, 资源利用低.

<br>
####1.3 总结

1. Java BIO 阻塞的方式, 代码简单, 逻辑清晰, 适合客户端数量不大的情况下使用.




<br>
##2. Java BIO

####2.1 使用例子

```java
ServerSocketChannel serverChannel = ServerSocketChannel.open();
serverChannel.configureBlocking(false);

ServerSocket ssocket = serverChannel.socket();
ssocket.bind(new InetSocketAddress(port));

Selector selector = Selector.open();
serverChannel.register(selector, SelectionKey.OP_ACCEPT);

final ByteBuffer msg = ByteBuffer.wrap("Hi!\r\n".getBytes());
for (;;) {
	try {
		selector.select();
	} catch (IOException ex) {
		ex.printStackTrace();
		// handle exception
		break;
	}

	Set<SelectionKey> readyKeys = selector.selectedKeys();
	Iterator<SelectionKey> iterator = readyKeys.iterator();
	while (iterator.hasNext()) {
		SelectionKey key = iterator.next();
		iterator.remove();
		try {
			if (key.isAcceptable()) {
				ServerSocketChannel server = (ServerSocketChannel) key.channel();
				SocketChannel client = server.accept();
				client.configureBlocking(false);
				client.register(selector, SelectionKey.OP_WRITE | SelectionKey.OP_READ, msg.duplicate());
				System.out.println("Accepted connection from " + client);
			}
			if (key.isWritable()) {
				SocketChannel client = (SocketChannel) key.channel();
				ByteBuffer buffer = (ByteBuffer) key.attachment();
				while (buffer.hasRemaining()) {
					if (client.write(buffer) == 0) {
						break;
					}
				}
				client.close();
			}
		} catch (IOException ex) {
			key.cancel();
			try {
				key.channel().close();
			} catch (IOException cex) {
				// ignore on close
			}
		}
	}
}
```

<br>
####2.2 主要问题

1. 逻辑复杂, 代码复杂, 容易出BUG.

<br>
####2.3 总结

1. 高性能, 使用一个专门的线程来轮询各种事件, 将BIO中分散到各个线程中的等待集中起来轮询, 



Java Network NIO
----

* 核心概念
		将原本

* 一般使用流程
	1. 

[Netty](http://netty.io/)是什么
----

		Netty是使用Java开发基于事件驱动的异步网络编程框架用于帮助开发者快速方便的构建高性能的网络应用.




为什么高性能, 如何实现高性能的

怎样实现事件驱动的

核心组建

构建流程(客户端, 服务端)

安全 SSL/TLS




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

