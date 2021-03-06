//
//  ANEExtensionFunc.m
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/1.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import "ANEExtensionFunc.h"
#import "ANETypeConversion.h"
#import "SharedManager.h"
#import "SharedDataModel.h"
#import "PayManager.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>



#define DISPATCH_STATUS_EVENT(extensionContext, code, status) FREDispatchStatusEventAsync((extensionContext), (uint8_t*)code, (uint8_t*)status)

@interface ANEExtensionFunc ()
@property (nonatomic, assign) FREContext context;
@property (nonatomic, strong) ANETypeConversion *converter;

@property (nonatomic, strong) AVPlayerViewController * avPlayer;
@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayer;


@end

@implementation ANEExtensionFunc

- (instancetype)initWithContext:(FREContext)extensionContext {
    
    self = [super init];
    if (self) {
        self.context = extensionContext;
        self.converter = [[ANETypeConversion alloc] init];
    }
    return self;
}

// 注册分享库
- (FREObject)registerShareSDK {
    
    [[SharedManager sharedManager] registerSharedSDKs];
    return NULL;
}

// 发送文字
- (FREObject)sendText:(FREObject)text {
    
    NSString *value = nil;
    FREResult ret = [_converter FREObject2NString:text toNString:&value];
    if (ret == FRE_OK) {
        SharedDataModel *model = [[SharedDataModel alloc] init];
        model.dataType = SharedDataTypeText;
        model.content = value;
        
        [[SharedManager sharedManager] sharedData:model finish:^(NSInteger statusCode, id resp) {
            //
            
            
        }];
    }
    
    return NULL;
}

// 发送链接
- (FREObject)sendLinkTitle:(FREObject)title text:(FREObject)text url:(FREObject)url {
    
    NSString *value = nil;
    FREResult ret = [_converter FREObject2NString:url toNString:&value];
    if (ret == FRE_OK) {
        SharedDataModel *model = [[SharedDataModel alloc] init];
        model.dataType = SharedDataTypeURL;
        model.url = value;
        
        
        ret = [_converter FREObject2NString:title toNString:&value];
        if (ret == FRE_OK ) {
            model.title = value;
        }
        
        ret = [_converter FREObject2NString:text toNString:&value];
        if (ret == FRE_OK ) {
            model.content = value;
        }
        
        [[SharedManager sharedManager] sharedData:model finish:^(NSInteger statusCode, id resp) {
            //
            NSString *strstatusCode = [NSString stringWithFormat:@"%ld",(long)statusCode];
            DISPATCH_STATUS_EVENT(self.context, [@"shareCallback" UTF8String], [strstatusCode UTF8String]);
        }];

    }

    return NULL;
}

// 发送本地图片
- (FREObject)sendImage:(FREObject)image {
    
    UIImage *value = nil;
    FREResult ret = [_converter FREObject2UIImage:image toUIImage:&value];
    if (ret == FRE_OK) {
        SharedDataModel *model = [[SharedDataModel alloc] init];
        model.dataType = SharedDataTypeImage;
        model.imageData = UIImagePNGRepresentation(value);
        
        UIImage *thumb = [self.converter thumbnailOfImage:value withMaxSize:100];
        model.thumbImage = thumb;
        
        [[SharedManager sharedManager] sharedData:model finish:^(NSInteger statusCode, id resp) {
            //
            NSString *strstatusCode = [NSString stringWithFormat:@"%ld",(long)statusCode];
            DISPATCH_STATUS_EVENT(self.context, [@"shareCallback" UTF8String], [strstatusCode UTF8String]);
        }];
        
    }
    
    return NULL;
    
}

// 发送远程图片
-(FREObject)sendImageUrl:(FREObject)imgUrl {
    
    NSString *value = nil;
    FREResult ret = [_converter FREObject2NString:imgUrl toNString:&value];
    if (ret == FRE_OK) {
        
        SharedDataModel *model = [[SharedDataModel alloc] init];
        model.dataType = SharedDataTypeImage;
        
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:value]]];
        model.imageData = UIImagePNGRepresentation(image);
        
        UIImage *thumb = [self.converter thumbnailOfImage:image withMaxSize:100];
        model.thumbImage = thumb;
        
        [[SharedManager sharedManager] sharedData:model finish:^(NSInteger statusCode, id resp) {
            //
            NSString *strstatusCode = [NSString stringWithFormat:@"%ld",(long)statusCode];
            DISPATCH_STATUS_EVENT(self.context, [@"shareCallback" UTF8String], [strstatusCode UTF8String]);
        }];
    }
    
    return NULL;
}

- (FREObject)loginByWX {
    [[SharedManager sharedManager] loginByWX:^(NSInteger statusCode, id resp) {
        //
        if ([resp isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = resp;
            NSString *nickname = [data objectForKey:@"nickname"];
            NSString *unionid = [data objectForKey:@"unionid"];
            
            NSString *message = [nickname stringByAppendingFormat:@"###%@",unionid];
            
            DISPATCH_STATUS_EVENT(self.context,[@"login_function_wx" UTF8String],[message UTF8String]);
            
        }

    }];
    return NULL;
}

- (FREObject)loginByQQ {
//    id delegate = [UIApplication sharedApplication].delegate;
//    NSString *appName = NSStringFromClass([delegate class]);
//    
//    DISPATCH_STATUS_EVENT(self.context,[@"login_function_qq" UTF8String],[appName UTF8String]);
    
    [[SharedManager sharedManager] loginByQQ:^(NSInteger statusCode, id resp) {
        //
        if ([resp isKindOfClass:[NSString class]]) {
            NSString *openId = resp;
            
            NSString *message = [openId stringByAppendingFormat:@"###%@",openId];
            
            DISPATCH_STATUS_EVENT(self.context,[@"login_function_qq" UTF8String],[message UTF8String]);
            
        }
        
    }];
    return NULL;
}

// 判断手机有没有安装：微信、QQ、新浪微博
- (FREObject)isAppInstalled {
    BOOL isInstall = [[SharedManager sharedManager] isInstallSharedApp];
    
    return [_converter bool2FREObject:isInstall];
}

- (FREObject)payMoney:(FREObject)money {
    NSUInteger uMoney = 0;
    [_converter FREObject2NSUInteger:money toNSUInteger:&uMoney];
    [[PayManager sharedManager] payMoney:uMoney finish:^(NSInteger statusCode, id resp) {
        //
        NSString *strstatusCode = [NSString stringWithFormat:@"%ld",(long)statusCode];
        DISPATCH_STATUS_EVENT(self.context, [@"payCallback" UTF8String], [strstatusCode UTF8String]);
    }];
    
    return NULL;
}


- (FREObject)playAV:(FREObject)text {
    return [self play:text isLoc:NO];
}


- (FREObject)playAVForLocal:(FREObject)text {
    return [self play:text isLoc:YES];
}

- (FREObject)play:(FREObject)text isLoc:(BOOL)isLoc {
    NSString *value = nil;
    FREResult ret = [_converter FREObject2NString:text toNString:&value];
    if (ret == FRE_OK) {
        
        NSURL *url = [NSURL URLWithString:value];
        if (isLoc) {
            url = [NSURL fileURLWithPath:value];
        }
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
            // iOS 9.0 以上系统的处理
            [self play9:url];
        } else {
            // iOS 9.0 以下系统的处理
            [self play8:url];
        }
    }
    
    DISPATCH_STATUS_EVENT(self.context, [@"play" UTF8String], [@"play" UTF8String]);
    return NULL;
}

- (void)play8:(NSURL *)URL {
    _moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:URL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayer.moviePlayer];
    [_moviePlayer.moviePlayer setControlStyle: MPMovieControlStyleFullscreen];
    //[_moviePlayer.moviePlayer play];
    
    UIApplication *application = [UIApplication sharedApplication];
    UIViewController *rootVC = application.keyWindow.rootViewController;
    [rootVC presentMoviePlayerViewControllerAnimated:_moviePlayer];
}

- (void)movieFinishedCallback:(NSNotification *)notify {
    
    MPMoviePlayerController *vc = [notify object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:vc];
    
    _moviePlayer = nil;
}

- (void)play9:(NSURL *)URL {
    _avPlayer = [[AVPlayerViewController alloc] init];
    _avPlayer.player = [[AVPlayer alloc] initWithURL:URL];
    /*
     可以设置的值及意义如下：
     AVLayerVideoGravityResizeAspect   不进行比例缩放 以宽高中长的一边充满为基准
     AVLayerVideoGravityResizeAspectFill 不进行比例缩放 以宽高中短的一边充满为基准
     AVLayerVideoGravityResize     进行缩放充满屏幕
     */
    _avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
    //[_avPlayer.player play];
    
    UIApplication *application = [UIApplication sharedApplication];
    UIViewController *rootVC = application.keyWindow.rootViewController;
    [rootVC presentViewController:_avPlayer animated:YES completion:nil];
    
}

@end
