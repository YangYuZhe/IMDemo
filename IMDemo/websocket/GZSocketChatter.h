//
//  GZSocketChatter.h
//  IMChatTool
//
//  Created by 杨雨哲 on 16/3/27.
//  Copyright © 2016年 gozap. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GZSocketChatter;
@protocol GZSocketChatterDelegate <NSObject>
- (void)socketChatterDidOpen:(GZSocketChatter *)socketChatter;
- (void)socketChatter:(GZSocketChatter *)socketChatter didReceiveMessage:(id)message;
- (void)socketChatter:(GZSocketChatter *)socketChatter didFailWithError:(NSError *)error;
- (void)socketChatter:(GZSocketChatter *)socketChatter didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
@end

@interface GZSocketChatter : NSObject
@property (nonatomic, weak) id<GZSocketChatterDelegate> delegate;
- (instancetype)initWithUrl:(NSString *)url;
- (void)open;
- (void)close;
- (void)sendMessage:(id)message; // Send a UTF8 String or Data.
- (BOOL)isConnected;
@end
