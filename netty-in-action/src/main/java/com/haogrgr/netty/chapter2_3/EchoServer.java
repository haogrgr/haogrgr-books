package com.haogrgr.netty.chapter2_3;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;

public class EchoServer {

	private final int port = 9999;

	public static void main(String[] args) throws Exception {
		EchoServer server = new EchoServer();
		server.start();
	}

	public void start() throws Exception {
		EchoServerHandler hander = new EchoServerHandler();
		NioEventLoopGroup group = new NioEventLoopGroup();

		try {
			ServerBootstrap bootstrap = new ServerBootstrap();
			bootstrap.group(group);
			bootstrap.channel(NioServerSocketChannel.class);
			bootstrap.localAddress(port);
			bootstrap.childHandler(new ChannelInitializer<SocketChannel>() {
				@Override
				protected void initChannel(SocketChannel ch) throws Exception {
					ch.pipeline().addLast(hander);
				}
			});

			ChannelFuture future = bootstrap.bind().sync();
			future.channel().closeFuture().sync();
		} finally {
			group.shutdownGracefully().sync();
		}

	}
}
