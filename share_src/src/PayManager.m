//
//  PayManager.m
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/12.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import "PayManager.h"
#import "AIActionSheet.h"
#import "PlatformConfigure.h"

// 微信平台
#import "WechatAuthSDK.h"
#import "WXApiObject.h"
#import "WXApi.h"

@interface AIPayPlatformSDKInfo : NSObject
@property (nonatomic, assign) AIPlatform platform;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;


+ (instancetype)platform:(AIPlatform)platform
                   appId:(NSString*)appId
                  secret:(NSString*)appSecret;
@end

@implementation AIPayPlatformSDKInfo
+ (instancetype)platform:(AIPlatform)platform
                   appId:(NSString*)appId
                  secret:(NSString*)appSecret
{
    
    AIPayPlatformSDKInfo *sdk = [[AIPayPlatformSDKInfo alloc] init];
    sdk.platform = platform;
    sdk.appId = appId;
    sdk.appSecret = appSecret;
    return sdk;
}

@end

@interface PayManager ()<AIActionSheetDelegate>

@property (nonatomic, strong) AIActionSheet                             *actionSheet;
@property (nonatomic, copy) AIPayFinishBlock                            finishBlock;
@property (nonatomic, strong) NSMutableArray<AIPayPlatformSDKInfo *>    *sdkInfos;
@property (nonatomic, assign) NSUInteger money;
@end

@implementation PayManager

+ (PayManager *)sharedManager {
    static PayManager *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[super allocWithZone:NULL] init];
    });
    return obj;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedManager];
}

- (instancetype)copy {
    return [[self class] sharedManager];
}

- (instancetype)init {
    if (self = [super init]) {
        self.sdkInfos = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)registerPaySDKs {
    AIPayPlatformSDKInfo *sdk1 = [AIPayPlatformSDKInfo platform:AIPlatformWechat appId:WeiXinSDKAppId secret:WeiXinSDKAppSecret];
    
    //
    [[PayManager sharedManager] registerPayPlatform:[NSArray arrayWithObjects:sdk1,nil]];
}

- (BOOL)isInstallPayApp {
    return [WXApi isWXAppInstalled];
}

- (void)registerPayPlatform:(NSArray<AIPayPlatformSDKInfo*> *)platforms {
    
    __weak typeof(self)wSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self)sSelf = wSelf;
        [sSelf.sdkInfos removeAllObjects];
        [sSelf.sdkInfos addObjectsFromArray:platforms];
        
        
        if (_actionSheet == nil) {
            self.actionSheet = [[ AIActionSheet alloc] initInParentView:[UIApplication sharedApplication].keyWindow.rootViewController.view delegate:self];
        }
        
        [_actionSheet clearAllItems];
        
        NSString *resPath = [[NSBundle mainBundle] pathForResource:@"SharedUI" ofType:@"bundle"];
        
        for (AIPayPlatformSDKInfo *item  in platforms) {
            AIPlatform platform = [item platform];
            
            if (platform == AIPlatformWechat) {
                // 微信
                if (![[PlatformConfigure sharedConfigure] isRegisterPlatform:platform]) {
                    [WXApi registerApp:[item appId] withDescription:NSStringFromClass([sSelf class])];
                    [[PlatformConfigure sharedConfigure] addRegisterPlatform:platform];
                }
                
                AISheetItem * actionSheetitem = [[AISheetItem alloc] init];
                if (IS_RETINA) {
                    actionSheetitem.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechat@2x.png"];
                } else {
                    actionSheetitem.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechat.png"];
                }
                
                actionSheetitem.title = @"微信";
                [_actionSheet addActionItem:actionSheetitem];
            }
        }
    });
}


- (void)payMoney:(NSUInteger)money finish:(AIPayFinishBlock)finishBlock {
    self.finishBlock = finishBlock;
    self.money = money;
    if (_actionSheet) {
        [_actionSheet show];
    }
}

- (void)payByWeixin {
    
#define kNetworkServerIP            @"http://101.69.181.210:80"
#define kNetworkAPIServer           kNetworkServerIP@"/tuwen_web"
    //weiXinToPay/wxToPay
    NSURL *url = [NSURL URLWithString:kNetworkAPIServer@"weiXinToPay/wxToPay"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //设置request
    request.HTTPMethod = @"POST";
    
    NSDictionary* param =[[NSDictionary alloc] initWithObjectsAndKeys:
                          @"1122",@"userId",
                          WeiXinSDKAppId,@"appid",
                          WeiXinSDKAppSecret,@"appsecret",
                          WeiXinBusinessNo,@"partner",
                          [NSString stringWithFormat:@"%u",_money*100],@"money",
                          @"WEB",@"device_info",
                          @"支付",@"body",
                          "192.168.1.1",@"spbill_create_ip",
                          @"CNY",@"fee_type",
                          nil];
    
    NSString *bodyString = @"";
    for (NSString*key in [param allKeys]) {
        NSString *value = [param objectForKey:key];
        bodyString = [bodyString stringByAppendingFormat:@"%@=%@",key,value];
        if (![key isEqualToString:[[param allKeys] lastObject]]) {
            bodyString = [bodyString stringByAppendingString:@"&"];
        }
    }

    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            //
//            WXPayResult *wxPay = (WXPayResult*)result;
//            
//            PayReq *request = [[PayReq alloc] init];
//            request.partnerId =  wxPay.partnerid;
//            request.prepayId = wxPay.prepayid;
//            request.package = wxPay.package;
//            request.nonceStr = wxPay.noncestr;
//            request.timeStamp = [wxPay.timestamp intValue];
//            request.sign = wxPay.sign;
//            [WXApi sendReq:request];

        });
        
    }];
    // 使用resume方法启动任务
    [dataTask resume];
}

#pragma mark - AIActionSheetDelegate
- (void)didSelectedActionSheet:( AIActionSheet *)actionSheet buttonIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex != buttonIndex) {
        AIPayPlatformSDKInfo *platformInfo = [_sdkInfos objectAtIndex:buttonIndex];
        if (platformInfo.platform == AIPlatformWechat)  {
            //
            [self payByWeixin];
        }
    }
}

@end
