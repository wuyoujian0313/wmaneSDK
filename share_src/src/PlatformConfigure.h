//
//  PlatformConfigure.h
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/12.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>

// AppDelegate的名称，即，main的第三个参数值
#define AppDelegateClassName        @"CTAppDelegate"


// 目前我们这个开发库只对接：微信、QQ、微博
#define QQSDKAppKey                 @"alkvsxWc7Eh7GwGk"
#define QQSDKAppId                  @"1105106734"

#define WeiXinSDKAppSecret          @"dce5699086e990df3104052ce298f573"
#define WeiXinSDKAppId              @"wx7a296d05150143e5"
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
    AIInvokingStatusCodeUnintallApp,          // 未安装对应的分享平台的应用
};

@interface PlatformConfigure : NSObject

+ (PlatformConfigure *)sharedConfigure;

- (void)addRegisterPlatform:(AIPlatform)platform;
- (BOOL)isRegisterPlatform:(AIPlatform)platform;

@end
