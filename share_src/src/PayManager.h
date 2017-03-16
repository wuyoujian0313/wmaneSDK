//
//  PayManager.h
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/12.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WeiXinSDKAppSecret          @"dce5699086e990df3104052ce298f573"
#define WeiXinSDKAppId              @"wx7a296d05150143e5"

typedef void(^AIPayFinishBlock)(NSInteger statusCode,id resp);

@interface PayManager : NSObject

+ (PayManager *)sharedManager;
- (void)registerPaySDKs;
- (BOOL)isInstallPayApp;

- (void)payMoney:(NSUInteger)money finish:(AIPayFinishBlock)finishBlock;

@end
