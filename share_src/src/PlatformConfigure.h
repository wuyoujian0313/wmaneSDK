//
//  PlatformConfigure.h
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/12.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>

//// AppDelegate的名称，即，main的第三个参数值
//#define AppDelegateClassName        @"AppDelegate"

// AppDelegate的名称，即，main的第三个参数值
#define AppDelegateClassName        @"CTAppController"


// 目前我们这个开发库只对接：微信、QQ、微博

// 微信 - 北汽电工
#define QQSDKAppKey                 @"x8uJ8UZ96u5AddjP"
#define QQSDKAppId                  @"1106041578"

// 微信 - 北汽电机
//#define QQSDKAppKey                 @"Hw4msb01bjk4X17l"
//#define QQSDKAppId                  @"1106056265"


// 北汽电机
//#define WeiXinSDKAppSecret          @"fedba484c5f88fc3398eee6bda007dce"
//#define WeiXinSDKAppId              @"wxf74876d011fb1356"
//#define WeiXinBusinessNo            @"1326100701"

// 微信 - 北汽电工
#define WeiXinSDKAppSecret          @"d2f36fee5809ea6d1909ff56e29f1e83"
#define WeiXinSDKAppId              @"wx828ddb181a65570c"
#define WeiXinBusinessNo            @"1326100701"

#define WeiboAppKey                 @"2045436852"
#define kWeiboRedirectURI           @"http://www.sina.com"


#define IS_RETINA ([UIScreen mainScreen].scale >= 2.0)

typedef NS_ENUM(NSInteger, AIPlatform) {
    AIPlatformWechat = 100,
    AIPlatformQQ,
    AIPlatformWeibo,
};

typedef NS_ENUM(NSInteger, AIInvokingStatusCode) {
    AIInvokingStatusCodeDone = 1000,          // 调起分享平台的应用成功
    AIInvokingStatusCodeAuthDone,          // 调起授权成功
    AIInvokingStatusCodeUnintallApp,          // 未安装对应的分享平台的应用
};

@interface PlatformConfigure : NSObject

+ (PlatformConfigure *)sharedConfigure;

- (void)addRegisterPlatform:(AIPlatform)platform;
- (BOOL)isRegisterPlatform:(AIPlatform)platform;

@end
