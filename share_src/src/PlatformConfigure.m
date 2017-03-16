//
//  PlatformConfigure.m
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/12.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import "PlatformConfigure.h"

@interface PlatformConfigure ()
@property (nonatomic, strong) NSMutableArray *regiteredSDKs;
@end

@implementation PlatformConfigure

+ (PlatformConfigure *)sharedConfigure {
    static PlatformConfigure *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[super allocWithZone:NULL] init];
    });
    return obj;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedConfigure];
}

- (instancetype)copy {
    return [[self class] sharedConfigure];
}

- (instancetype)init {
    if (self = [super init]) {
        self.regiteredSDKs = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addRegisterPlatform:(AIPlatform)platform {
    [_regiteredSDKs addObject:[NSNumber numberWithInteger:platform]];
}

- (BOOL)isRegisterPlatform:(AIPlatform)platform {
    return [_regiteredSDKs containsObject:[NSNumber numberWithInteger:platform]];
}
@end
