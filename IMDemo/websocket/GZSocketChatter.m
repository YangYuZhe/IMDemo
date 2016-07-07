//
//  GZSocketChatter.m
//  IMChatTool
//
//  Created by 杨雨哲 on 16/3/27.
//  Copyright © 2016年 gozap. All rights reserved.
//

#import "GZSocketChatter.h"
#import "SRWebSocket.h"

@interface GZSocketChatter ()<SRWebSocketDelegate>
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, assign) BOOL connected;
@end

@implementation GZSocketChatter

- (instancetype)initWithUrl:(NSString *)url
{
    if (self = [super init]) {
        _socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        _socket.delegate = self;
        _connected = NO;
    }
    return self;
}

- (void)open
{
    [_socket open];
}

- (void)close
{
    [_socket close];
}

- (void)sendMessage:(id)message
{
    [_socket send:message];
}

- (BOOL)isConnected
{
    return _connected;
}


#pragma mark - SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"did close with code : %d and reason:%@", code, reason);
    if (_delegate && [_delegate respondsToSelector:@selector(socketChatter:didCloseWithCode:reason:wasClean:)]) {
        [_delegate socketChatter:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"did fail with error : %@",error.description);
    if (_delegate && [_delegate respondsToSelector:@selector(socketChatter:didFailWithError:)]) {
        [_delegate socketChatter:self didFailWithError:error];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"did receive message : %@",message);
    if (_delegate && [_delegate respondsToSelector:@selector(socketChatter:didReceiveMessage:)]) {
        [_delegate socketChatter:self didReceiveMessage:message];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"open succeed");
    if (_delegate && [_delegate respondsToSelector:@selector(socketChatterDidOpen:)]) {
        [_delegate socketChatterDidOpen:self];
    }
}

@end
