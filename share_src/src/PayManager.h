//
//  PayManager.h
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/12.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AIPayFinishBlock)(NSInteger statusCode,id resp);

@interface PayManager : NSObject

+ (PayManager *)sharedManager;
- (void)registerPaySDKs;
- (BOOL)isInstallPayApp;

- (void)payMoney:(NSUInteger)money finish:(AIPayFinishBlock)finishBlock;

@end
