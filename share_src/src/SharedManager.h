//
//  SharedManager.h
//  CommonProject
//
//  Created by wuyoujian on 16/5/12.
//  Copyright © 2016年 wuyoujian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SharedDataModel.h"


// @param resp 是微信、qq和新浪微博的回调对象
// @param statusCode可以是AISharedStatusCode，也兼容QQ的QQApiSendResultCode
typedef void(^AISharedFinishBlock)(NSInteger statusCode,id resp);

// 单例模式类
@interface SharedManager : NSObject
+ (SharedManager *)sharedManager;

- (void)registerSharedSDKs;
- (BOOL)isInstallSharedApp;

- (void)loginByWX:(AISharedFinishBlock)finishBlock;
- (void)loginByQQ:(AISharedFinishBlock)finishBlock;
// 分享
- (void)sharedData:(SharedDataModel*)dataModel finish:(AISharedFinishBlock)finishBlock;
@end





