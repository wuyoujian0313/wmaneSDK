//
//  ANEExtensionFunc.h
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/1.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"

@interface ANEExtensionFunc : NSObject

- (instancetype)initWithContext:(FREContext)extensionContext;

// 注册分享库
- (FREObject)registerShareSDK;

// 发送文字
- (FREObject)sendText:(FREObject)text;

// 发送链接
- (FREObject)sendLinkTitle:(FREObject)title text:(FREObject)text url:(FREObject)url;

// 发送本地图片
- (FREObject)sendImage:(FREObject)image;

// 发送远程图片
-(FREObject)sendImageUrl:(FREObject)imgUrl;

// 判断手机有没有安装：微信、QQ、新浪微博
- (FREObject)isAppInstalled;

- (FREObject)loginByWX;
- (FREObject)loginByQQ;


- (FREObject)payMoney:(FREObject)money;

@end
