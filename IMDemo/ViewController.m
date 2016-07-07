//
//  ViewController.m
//  IMDemo
//
//  Created by yyz on 16/5/25.
//  Copyright © 2016年 gozap. All rights reserved.
//

#import "ViewController.h"
#import "GZSocketChatter.h"
#import "Reachability.h"

/**
 *  在项目中应用时每次此token都需要根据自己项目的gettoken api获取,以免连接IM时收到message_type=52的token失效提示，见openapi
 */
static NSString *const token = @"YdzLV_r0Q7K_lFtZP7tye5n5Jo81O4GaaLq1z6iRrwAEi36NXkuWZQuPlL3JyemJqrtVFI-TDtLHa-UXr_6FSA;IJFtyWMwIMou28ATefEEJRcHlB5uSi4fZYwSBbY1YW0Y7TCyYutChzLkR_o-0WouXB_T0Sy5eEebN-jBeFzC-w;IeDCWqGTMdvHgtmNtBYIIAmtmeKuAg_419YhXSWv7bfXtGKcHYjAinpraNRr4HWMGJVNVL_5i5SNfJ6pAJmDfQ";
static NSString *const serverRes = @"http://58.68.237.198:8034/master/server.do";

@interface ViewController ()<GZSocketChatterDelegate>
@property (strong, nonatomic) GZSocketChatter *socketChatter;
@property (strong, nonatomic) NSTimer *kaTimer; // 保持心跳的计时器
@property (nonatomic) Reachability *reach; // 网络状态

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UILabel *recieveLabel;
@end

@implementation ViewController

#pragma mark - 视图控制器生命周期
-(void)dealloc
{
    [self.reach stopNotifier];
    self.reach = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self cleanTimer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForReachability]; // 判断网络状态
}


- (void)registerForReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.reach = [Reachability reachabilityForInternetConnection];
    [self.reach startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)notify
{
    Reachability *reach = [notify object];
    if ([reach isKindOfClass:[Reachability class]]) {
        NetworkStatus status = [reach currentReachabilityStatus];
        if (status != NotReachable) {
            [self setupChatSession];
        }else{
            [self cleanTimer];
        }
    }
}

#pragma mark - 建立IM环境
/**
 *  token:根据自己的后台gettoken获取
 *  此方法中，获取了token,host,port，然后拼接websocket地址
 */
- (void)setupChatSession
{
    __block NSArray *hostList;
    
    NSURL *url = [NSURL URLWithString:serverRes];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSDictionary *resp = dict[@"resp"];
        NSDictionary *known_servers = resp[@"known_servers"];
        hostList = known_servers[@"message"];
        NSLog(@"hostList = %@",hostList);
        NSDictionary *ws = hostList[arc4random() % hostList.count];
        NSString *host = ws[@"host"];
        NSString *port = ws[@"port"];
        _socketChatter = [[GZSocketChatter alloc] initWithUrl:[NSString stringWithFormat:@"ws://%@:%@/messages?%@",host,port,token]];
        _socketChatter.delegate = self;
        [_socketChatter open];
    }];
    [task resume];
}

- (IBAction)setupChatSession:(id)sender {
    [self setupChatSession];
}


- (IBAction)sendMessage:(id)sender {
    NSString *jid = @"jid";
    [_socketChatter sendMessage:[NSString stringWithFormat:@"{\"type\":0,\"user\":{\"jid\":\"%@\"},\"content\":{\"text\":\"%@\"}}",jid,self.sendTextField.text]];
}


#pragma mark - GZSocketChatterDelegate
//
- (void)socketChatterDidOpen:(GZSocketChatter *)socketChatter
{
    // 这里的回调只能知道已经和服务器握手，不能保证IM连接成功，需要在recieveMessage中根据message_type判断
}



- (void)socketChatter:(GZSocketChatter *)socketChatter didReceiveMessage:(id)message
{
    NSDictionary *dict = [self parseJSONstringToDictionary:message];
    self.recieveLabel.text = message;
    if ([dict[@"message_type"] intValue] == 105) {
        // 得到了聊天消息
        
    NSString *idStr = dict[@"id"];
    [_socketChatter sendMessage:[NSString stringWithFormat:@"{\"message_type\":104,\"id\":\"%@\"}",idStr]]; //  收到聊天消息后需要回复服务器
    }else if ([dict[@"message_type"] intValue] == 52){
        // token失效的处理，重新获取token
        
    }else if ([dict[@"message_type"] intValue] == 51){
        // 确认处于连接成功状态的处理
        
        // 保持心跳
        if (!_kaTimer||![_kaTimer isValid]) {
            NSTimeInterval ti = 60;
            if ([self isNight]) {
                ti = 120;
            }
            _kaTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(keepAlive) userInfo:nil repeats:YES];
        }
    }
}

- (void)socketChatter:(GZSocketChatter *)socketChatter didFailWithError:(NSError *)error
{
    // 这里做失败处理,暂时不清楚IM服务器什么情况会失败
    
    [self cleanTimer];
    if ([self.reach currentReachabilityStatus] != NotReachable) {
        [self setupChatSession];
    }
}

- (void)socketChatter:(GZSocketChatter *)socketChatter didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    // 正常关闭1000
    if (code != 1000&&[self.reach currentReachabilityStatus]!= NotReachable) {
        [self cleanTimer];
        [self setupChatSession];
    }
}
- (void)keepAlive
{
    [_socketChatter sendMessage:@"{\"message_type\":0}"];
}

- (BOOL)isNight
{
    NSDate *date = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0) {
        NSInteger hour = [calender component:NSCalendarUnitHour fromDate:date];
        if (hour < 8 || hour >= 23) {
            return YES;
        }
        return NO;
    }else{
        NSDateComponents *dc = [calender components:NSCalendarUnitHour fromDate:date];
        if (dc.hour < 8 || dc.hour >= 23) {
            return YES;
        }
        return NO;
    }
}

- (void)cleanTimer
{
    if (_kaTimer) {
        [_kaTimer invalidate];
        _kaTimer = nil;
    }
}

- (void)cleanSocketChatter
{
    if (_socketChatter) {
        [_socketChatter close];
        _socketChatter.delegate = nil;
        _socketChatter = nil;
    }
}

- (NSDictionary *)parseJSONstringToDictionary:(NSString *)jsonString
{
    if (jsonString) {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        return jsonDict;
    }else{
        return nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
