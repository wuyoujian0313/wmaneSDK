//
//  SharedManager.m
//  CommonProject
//
//  Created by wuyoujian on 16/5/12.
//  Copyright © 2016年 wuyoujian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "SharedManager.h"
#import "AIActionSheet.h"
#import "PlatformConfigure.h"

// 微信平台
#import "WechatAuthSDK.h"
#import "WXApiObject.h"
#import "WXApi.h"

// QQ平台
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>
#import <TencentOpenAPI/sdkdef.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import <TencentOpenAPI/TencentMessageObject.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/TencentOAuthObject.h>

// 新浪微博
#import "WeiboSDK.h"




typedef NS_ENUM(NSInteger, AISharedPlatformScene) {
    AISharedPlatformSceneSession,   //聊天
    AISharedPlatformSceneTimeline,  //朋友圈&空间
    AISharedPlatformSceneFavorite,  //收藏
};

@interface AIWXSDKCallback : NSObject<WXApiDelegate>
@end

@interface AIWXSDKCallback ()
@property (nonatomic, copy) AISharedFinishBlock        finishBlock;
@end

@implementation AIWXSDKCallback

#pragma mark - WXApiDelegate
- (void)dealloc {
    self.finishBlock = nil;
}

- (void)onResp:(BaseResp*)resp {
    
    if ([resp isKindOfClass:[SendAuthResp class]]) {

        SendAuthResp *aresp = (SendAuthResp *)resp;
        if ([aresp.state isEqualToString:@"weimeitc_aneProject"]) {
            NSString *code = aresp.code;
            [self getAccessTokenWithCode:code];
        }
    }
    
}

- (void)getAccessTokenWithCode:(NSString *)code {
    
    NSString *urlString =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",WeiXinSDKAppId,WeiXinSDKAppSecret,code];
    NSURL *url = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *dataStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data){
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                if ([dict objectForKey:@"errcode"]) {
                    NSLog(@"%@",dict);
                } else {
                    /*
                     {
                     "access_token" = "tnSXfzh2w8zrDe8zCdi0m1ZmOR***************Ckz6S6xJLQFeUDgu5Hyhwyowg5fvOhW2ZpA7Rr_PGPPO8P1Sw";
                     "expires_in" = 7200;
                     openid = oKiGKvxz***************JEjaYTNZPmA6OU;
                     "refresh_token" = "piHYgVqYxjw8mGdS1Wrnq8bIihijEp_Tvz6K***************jveI4iv5MPvOyV9zIemT_YAzv5S9djY";
                     scope = "snsapi_userinfo";
                     unionid = "o6awM***************aYlc***************ft9-A";
                     }
                     */
                    [self getUserInfoWithAccessToken:[dict objectForKey:@"access_token"] andOpenId:[dict objectForKey:@"openid"]];
                }
            }
        });
    });
}


//使用AccessToken获取用户信息
- (void)getUserInfoWithAccessToken:(NSString *)accessToken andOpenId:(NSString *)openId {
    NSString *urlString =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",accessToken,openId];
    NSURL *url = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *dataStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (data) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                if ([dict objectForKey:@"errcode"]) {
                    //AccessToken失效
                }else {
                    NSLog(@"dictdict%@",dict);
                    if (_finishBlock) {
                        _finishBlock(AIInvokingStatusCodeAuthDone,dict);
                    }
                }
            }
        });
    });
}

@end

@interface AIQQSDKCallback : NSObject<QQApiInterfaceDelegate,TencentSessionDelegate>
@end

@interface AIQQSDKCallback ()
@property (nonatomic, copy) AISharedFinishBlock        finishBlock;
@property (nonatomic, strong) TencentOAuth  *qqAuth;
@end

@implementation AIQQSDKCallback

- (void)dealloc {
    self.finishBlock = nil;
}

- (void)onResp:(QQBaseResp *)resp {
    if (_finishBlock) {
        _finishBlock(AIInvokingStatusCodeDone,resp);
    }
}

- (void)onReq:(QQBaseReq *)req {}
- (void)isOnlineResponse:(NSDictionary *)response {}


/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin {
    
    if (_finishBlock) {
        _finishBlock(AIInvokingStatusCodeAuthDone,[_qqAuth openId]);
    }
    
}

/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled {
    
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork {
    
}


@end


@interface AISharedPlatformSDKInfo : NSObject
@property (nonatomic, assign) AIPlatform platform;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *redirectURI;//若无此参数，可以传入nil;

+ (instancetype)platform:(AIPlatform)platform
                   appId:(NSString*)appId
                  secret:(NSString*)appSecret
             redirectURI:(NSString*)redirectURI;
@end

@implementation AISharedPlatformSDKInfo
+ (instancetype)platform:(AIPlatform)platform
                   appId:(NSString*)appId
                  secret:(NSString*)appSecret
             redirectURI:(NSString*)redirectURI
{
    
    AISharedPlatformSDKInfo *sdk = [[AISharedPlatformSDKInfo alloc] init];
    sdk.platform = platform;
    sdk.appId = appId;
    sdk.appSecret = appSecret;
    sdk.redirectURI = redirectURI;
    return sdk;
}

@end

@interface inline_SharedPlatformScene : NSObject
@property (nonatomic, assign) AIPlatform platform;
@property (nonatomic, assign) AISharedPlatformScene scene;
+ (instancetype)scene:(AISharedPlatformScene)scene platform:(AIPlatform)platform;
@end

@implementation inline_SharedPlatformScene
+ (instancetype)scene:(AISharedPlatformScene)scene platform:(AIPlatform)platform {
    inline_SharedPlatformScene *sharedscene = [[inline_SharedPlatformScene alloc] init];
    sharedscene.scene = scene;
    sharedscene.platform = platform;
    return sharedscene;
}
@end

@interface SharedManager ()< AIActionSheetDelegate ,TencentSessionDelegate,WeiboSDKDelegate>

@property (nonatomic, strong) AIActionSheet                               *actionSheet;
@property (nonatomic, strong) NSMutableArray<inline_SharedPlatformScene*> *scenes;
@property (nonatomic, strong) SharedDataModel                             *sharedData;
@property (nonatomic, strong) TencentOAuth                                *qqOAuth;
@property (nonatomic, copy) AISharedFinishBlock                           finishBlock;
@property (nonatomic, strong) NSMutableArray<AISharedPlatformSDKInfo*>    *sdkInfos;

// 由于QQ和微信的回调API一样，为了统一使用AISharedFinishBlock做回调采用组合对象作为回调对象
@property (nonatomic, strong) AIWXSDKCallback *wxCallback;
@property (nonatomic, strong) AIQQSDKCallback *qqCallback;
@end

@implementation SharedManager

+ (SharedManager *)sharedManager {
    static SharedManager *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[super allocWithZone:NULL] init];
    });
    return obj;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [[self class] sharedManager];
}

- (instancetype)copy {
    return [[self class] sharedManager];
}

- (instancetype)init {
    if (self = [super init]) {
        self.wxCallback = [[AIWXSDKCallback alloc] init];
        self.qqCallback = [[AIQQSDKCallback alloc] init];
        self.sdkInfos = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (BOOL)handleOpenURL:(NSURL*)url {
    for (AISharedPlatformSDKInfo* sdk in _sdkInfos) {
        if ([[url absoluteString] hasPrefix:[sdk appId]]) {
            //微信回调
            return [WXApi handleOpenURL:url delegate:[SharedManager sharedManager].wxCallback];
        } else if ([[url absoluteString] hasPrefix:[NSString stringWithFormat:@"QQ%@",[sdk appId]]] || [[url absoluteString] hasPrefix:[NSString stringWithFormat:@"tencent%@",[sdk appId]]]) {
            //QQ回调
            [QQApiInterface handleOpenURL:url delegate:[SharedManager sharedManager].qqCallback];
            [TencentOAuth HandleOpenURL:url];
            return YES;
        } else if ([[url absoluteString] hasPrefix:[NSString stringWithFormat:@"wb%@",[sdk appId]]]) {
            //新浪微博回调
            return [WeiboSDK handleOpenURL:url delegate:[SharedManager sharedManager]];
        }
    }

    return YES;
}

- (void)registerSharedSDKs {
    
    NSMutableArray *SDKs = [[NSMutableArray alloc] initWithCapacity:0];

    if ([WXApi isWXAppInstalled] || 1) {
        AISharedPlatformSDKInfo *sdk1 = [AISharedPlatformSDKInfo platform:AIPlatformWechat appId:WeiXinSDKAppId secret:WeiXinSDKAppSecret redirectURI:nil];
        [SDKs addObject:sdk1];
    }
    
    if ([QQApiInterface isQQInstalled] || 1) {
        AISharedPlatformSDKInfo *sdk2 = [AISharedPlatformSDKInfo platform:AIPlatformQQ appId:QQSDKAppId secret:QQSDKAppKey redirectURI:nil];
        [SDKs addObject:sdk2];
    }
    
    if (![WeiboSDK isWeiboAppInstalled] || 1) {
        AISharedPlatformSDKInfo *sdk3 = [AISharedPlatformSDKInfo platform:AIPlatformWeibo appId:WeiboAppKey secret:WeiboAppKey redirectURI:kWeiboRedirectURI];
        [SDKs addObject:sdk3];
    }
    
    if ([SDKs count] > 0) {
        [[SharedManager sharedManager] registerSharedPlatform:SDKs];
    }
}

- (void)registerSharedPlatform:(NSArray<AISharedPlatformSDKInfo*> *)platforms {
    
    __weak typeof(self)wSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self)sSelf = wSelf;
        [sSelf.sdkInfos removeAllObjects];
        [sSelf.sdkInfos addObjectsFromArray:platforms];
        [_actionSheet clearAllItems];
        
        for (AISharedPlatformSDKInfo *item  in platforms) {
            AIPlatform platform = [item platform];
        
            if (platform == AIPlatformWechat) {
                // 微信
                
                if (![[PlatformConfigure sharedConfigure] isRegisterPlatform:platform]) {
                    [WXApi registerApp:[item appId]];
                    [[PlatformConfigure sharedConfigure] addRegisterPlatform:platform];
                }

                [sSelf addSharedPlatformScene:[inline_SharedPlatformScene scene:AISharedPlatformSceneSession platform:AIPlatformWechat]];
                [sSelf addSharedPlatformScene:[inline_SharedPlatformScene scene:AISharedPlatformSceneTimeline platform:AIPlatformWechat]];
                [sSelf addSharedPlatformScene:[inline_SharedPlatformScene scene:AISharedPlatformSceneFavorite platform:AIPlatformWechat]];
                
                
            } else if (platform == AIPlatformQQ) {
                //
                if (![[PlatformConfigure sharedConfigure] isRegisterPlatform:platform]) {
                    sSelf.qqOAuth = [[TencentOAuth alloc] initWithAppId:[item appId] andDelegate:sSelf];
                    [[PlatformConfigure sharedConfigure] addRegisterPlatform:platform];
                }
                
                
                [sSelf addSharedPlatformScene:[inline_SharedPlatformScene scene:AISharedPlatformSceneSession platform:AIPlatformQQ]];
                [sSelf addSharedPlatformScene:[inline_SharedPlatformScene scene:AISharedPlatformSceneTimeline platform:AIPlatformQQ]];
            } else if (platform == AIPlatformWeibo) {
                if (![[PlatformConfigure sharedConfigure] isRegisterPlatform:platform]) {
                    [WeiboSDK registerApp:[item appId]];
                    [[PlatformConfigure sharedConfigure] addRegisterPlatform:platform];
                }
                
                [sSelf addSharedPlatformScene:[inline_SharedPlatformScene scene:AISharedPlatformSceneTimeline platform:AIPlatformWeibo]];
            }
        }
    
    });
}

- (void)addSharedPlatformScene:(inline_SharedPlatformScene*)scene {
    
    if (_actionSheet == nil) {
        self.actionSheet = [[ AIActionSheet alloc] initInParentView:[UIApplication sharedApplication].keyWindow.rootViewController.view delegate:self];
        self.scenes = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    for (inline_SharedPlatformScene*item in _scenes) {
        if (item == scene) {
            return;
        }
    }
    
    NSString *resPath = [[NSBundle mainBundle] pathForResource:@"SharedUI" ofType:@"bundle"];
    AISheetItem * item = [[AISheetItem alloc] init];
    if (scene.platform == AIPlatformWechat ) {
        if (scene.scene == AISharedPlatformSceneSession) {
            if (IS_RETINA) {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechat@2x.png"];
            } else {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechat.png"];
            }
            
            item.title = @"微信好友";
        } else if (scene.scene == AISharedPlatformSceneTimeline) {
            if (IS_RETINA) {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechatTimeline@2x.png"];
            } else {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechatTimeline.png"];
            }
            
            item.title = @"微信朋友圈";
        } else if (scene.scene == AISharedPlatformSceneFavorite) {
            if (IS_RETINA) {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechatFav@2x.png"];
            } else {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_wechatFav.png"];
            }
            
            item.title = @"微信收藏";
        }
    } else if (scene.platform == AIPlatformQQ ) {
        if (scene.scene == AISharedPlatformSceneSession) {
            if (IS_RETINA) {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_qq@2x.png"];
            } else {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_qq.png"];
            }
            
            item.title = @"QQ";
        } else if (scene.scene == AISharedPlatformSceneTimeline) {
            if (IS_RETINA) {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_qqzoom@2x.png"];
            } else {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_qqzoom.png"];
            }
            
            item.title = @"QQ空间";
        }
    } else if (scene.platform == AIPlatformWeibo) {
        
        if (scene.scene == AISharedPlatformSceneTimeline) {
            if (IS_RETINA) {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_weibo@2x.png"];
            } else {
                item.iconPath = [resPath stringByAppendingPathComponent:@"icon_weibo.png"];
            }
            
            item.title = @"新浪微博";
        }
    }
    
     
    [_actionSheet addActionItem:item];
    [_scenes addObject:scene];
}

- (void)unstallAppMessage:(NSString *)message {
    UIAlertAction *aAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    //
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:aAction];
    
    UIApplication *application = [UIApplication sharedApplication];
    [application.keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)sharedData:(SharedDataModel*)dataModel finish:(AISharedFinishBlock)finishBlock {
    
    self.finishBlock = finishBlock;
    self.sharedData = dataModel;
    if (_actionSheet) {
        [_actionSheet show];
    }
}


- (BOOL)isInstallSharedApp {
    return [WXApi isWXAppInstalled] || [QQApiInterface isQQInstalled] || [WeiboSDK isWeiboAppInstalled];
}


- (void)shareToWeixin:(inline_SharedPlatformScene *)scene {
    
    self.wxCallback.finishBlock = _finishBlock;
    if (![WXApi isWXAppInstalled]) {
        if (_finishBlock) {
            _finishBlock(AIInvokingStatusCodeUnintallApp,nil);
        }
        
        [self unstallAppMessage:@"手机未安装微信客户端！"];
        return;
    }
    
    //微信
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.scene = scene.scene;
    
    if (_sharedData.dataType == SharedDataTypeText) {
        // 文字类型分享
        req.text = _sharedData.content;
        req.bText = YES;
    } else if (_sharedData.dataType == SharedDataTypeImage) {
        // 图片类型分享
        req.bText = NO;
        WXMediaMessage *message = [WXMediaMessage message];
        [message setThumbImage:_sharedData.thumbImage];
        
        WXImageObject *imageObject = [WXImageObject object];
        imageObject.imageData = _sharedData.imageData;
        message.mediaObject = imageObject;
        
        req.message = message;
        
    } else if (_sharedData.dataType == SharedDataTypeMusic) {
        // 音乐类型分享
        req.bText = NO;
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = _sharedData.title;
        message.description = _sharedData.content;
        [message setThumbImage:_sharedData.thumbImage];
        
        WXMusicObject *musicObject = [WXMusicObject object];
        musicObject.musicUrl = _sharedData.url;
        musicObject.musicLowBandUrl = musicObject.musicUrl;
        musicObject.musicDataUrl = musicObject.musicUrl;
        musicObject.musicLowBandDataUrl = musicObject.musicUrl;
        message.mediaObject = musicObject;
        
        req.message = message;
    } else if (_sharedData.dataType == SharedDataTypeVideo) {
        // 视频类型分享
        req.bText = NO;
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = _sharedData.title;
        message.description = _sharedData.content;
        [message setThumbImage:_sharedData.thumbImage];
        
        WXVideoObject *videoObject = [WXVideoObject object];
        videoObject.videoUrl = _sharedData.url;
        videoObject.videoLowBandUrl = _sharedData.lowBandUrl;
        message.mediaObject = videoObject;
        
        req.message = message;
    } else if (_sharedData.dataType == SharedDataTypeURL) {
        // 网页类型分享
        req.bText = NO;
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = _sharedData.title;
        message.description = _sharedData.content;
        [message setThumbImage:_sharedData.thumbImage];
        
        WXWebpageObject *webpageObject = [WXWebpageObject object];
        webpageObject.webpageUrl = _sharedData.url;
        message.mediaObject = webpageObject;
        
        req.message = message;
        
    } else {
        
    }
    
    [WXApi sendReq:req];
}

- (void)loginByWX:(AISharedFinishBlock)finishBlock {
    
    self.finishBlock = finishBlock;
    self.wxCallback.finishBlock = _finishBlock;
    
    SendAuthReq* req =[[SendAuthReq alloc ] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"weimeitc_aneProject";
    //第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
}

- (void)loginByQQ:(AISharedFinishBlock)finishBlock {
    
    self.finishBlock = finishBlock;
    self.qqCallback.finishBlock = _finishBlock;
    
   
    
    NSArray* permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            nil];
    TencentOAuth *tencentOAuth = [[TencentOAuth alloc] initWithAppId:QQSDKAppId andDelegate:self.qqCallback];
    self.qqCallback.qqAuth = tencentOAuth;
    [tencentOAuth authorize:permissions inSafari:NO];

    
}

- (void)shareToQQ:(inline_SharedPlatformScene *)scene {
    //QQ
    self.qqCallback.finishBlock = _finishBlock;
    if (![QQApiInterface isQQInstalled]) {
        if (_finishBlock) {
            _finishBlock(AIInvokingStatusCodeUnintallApp,nil);
        }
        [self unstallAppMessage:@"手机未安装QQ客户端！"];
        return;
    }
    
    if (_sharedData.dataType == SharedDataTypeText || _sharedData.dataType == SharedDataTypeURL) {
        // 文字类型分享
        NSString *text = _sharedData.dataType == SharedDataTypeText ? _sharedData.content : _sharedData.url;
        
        if (scene.scene == AISharedPlatformSceneSession) {
            // 分享到聊天
            QQApiTextObject* txtObj = [QQApiTextObject objectWithText:text];
            SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:txtObj];
            QQApiSendResultCode sentCode = [QQApiInterface sendReq:req];
            [self handleSendQQResult:sentCode];
            
            
        } else if (scene.scene == AISharedPlatformSceneTimeline) {
            // 分享到空间
            
            QQApiTextObject* txtObj = [QQApiTextObject objectWithText:text];
            
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:txtObj];
            QQApiSendResultCode sentCode = [QQApiInterface SendReqToQZone:req];
            [self handleSendQQResult:sentCode];
            
        }
        
    } else if (_sharedData.dataType == SharedDataTypeImage) {
        // 图片类型分享
        if (scene.scene == AISharedPlatformSceneSession) {
            
            // 分享到聊天
            QQApiImageObject* img = [QQApiImageObject objectWithData:_sharedData.imageData previewImageData:UIImagePNGRepresentation(_sharedData.thumbImage) title:_sharedData.title description:_sharedData.content];
            SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
            
            QQApiSendResultCode sentCode = [QQApiInterface sendReq:req];
            [self handleSendQQResult:sentCode];
            
        } else if (scene.scene == AISharedPlatformSceneTimeline) {
            
            // 分享到空间
            QQApiImageArrayForQZoneObject *img = [QQApiImageArrayForQZoneObject objectWithimageDataArray:[NSArray arrayWithObject:_sharedData.imageData] title:_sharedData.title];
            SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
            QQApiSendResultCode sentCode = [QQApiInterface SendReqToQZone:req];
            [self handleSendQQResult:sentCode];
        }
        
    } else if (_sharedData.dataType == SharedDataTypeVideo) {
        // 视频类型分享
        if (scene.scene == AISharedPlatformSceneSession) {
            
            // 分享到聊天
            NSURL* url = [NSURL URLWithString:_sharedData.url];
            QQApiNewsObject* img = [QQApiNewsObject objectWithURL:url title:_sharedData.title description:_sharedData.content previewImageData:UIImagePNGRepresentation(_sharedData.thumbImage)];
            
            SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
            QQApiSendResultCode sentCode = [QQApiInterface sendReq:req];
            [self handleSendQQResult:sentCode];
            
        } else if (scene.scene == AISharedPlatformSceneTimeline) {
            
            // 分享到空间
            QQApiVideoForQZoneObject *video = [QQApiVideoForQZoneObject objectWithAssetURL:_sharedData.url title:_sharedData.title];
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:video];
            QQApiSendResultCode sentCode = [QQApiInterface SendReqToQZone:req];
            [self handleSendQQResult:sentCode];
        }
    }
}


- (void)shareToWeibo:(inline_SharedPlatformScene *)scene {
    
    // 新浪微博
    
    if (![WeiboSDK isWeiboAppInstalled]) {
        if (_finishBlock) {
            _finishBlock(AIInvokingStatusCodeUnintallApp,nil);
        }
        [self unstallAppMessage:@"手机未安装微博客户端！"];
        return;
    }
    
    
    if (scene.scene == AISharedPlatformSceneTimeline) {
        
        // 分享到新浪微博
        WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
        for (AISharedPlatformSDKInfo* sdk in _sdkInfos){
            if (sdk.platform == AIPlatformWeibo) {
                authRequest.redirectURI = sdk.redirectURI;
            }
        }
        authRequest.scope = @"all";
        
        WBMessageObject *message = [WBMessageObject message];
        if (_sharedData.dataType == SharedDataTypeText) {
            // 文字类型分享
            message.text = _sharedData.content;
        } else if (_sharedData.dataType == SharedDataTypeImage) {
            // 图片类型分享
            WBImageObject *image = [WBImageObject object];
            image.imageData = _sharedData.imageData;
            message.imageObject = image;
        } else if (_sharedData.dataType == SharedDataTypeMusic) {
            // 音乐类型分享
            WBMusicObject *music = [WBMusicObject object];
            music.title = _sharedData.title;
            music.thumbnailData = UIImagePNGRepresentation(_sharedData.thumbImage);
            music.description = _sharedData.content;
            music.musicUrl = _sharedData.url;
            music.musicLowBandUrl = _sharedData.lowBandUrl;
            message.mediaObject = music;
        } else if (_sharedData.dataType == SharedDataTypeVideo) {
            // 视频类型分享
            WBVideoObject *video = [WBVideoObject object];
            video.title = _sharedData.title;
            video.thumbnailData = UIImagePNGRepresentation(_sharedData.thumbImage);
            video.videoUrl = _sharedData.url;
            video.videoLowBandUrl = _sharedData.lowBandUrl;
            message.mediaObject = video;
        } else if (_sharedData.dataType == SharedDataTypeURL) {
            // 网页类型分享
            WBWebpageObject *webpage = [WBWebpageObject object];
            webpage.objectID = NSStringFromClass([self class]);
            webpage.title = _sharedData.title;
            webpage.description = _sharedData.content;
            webpage.thumbnailData = UIImagePNGRepresentation(_sharedData.thumbImage);
            webpage.webpageUrl = _sharedData.url;
            message.mediaObject = webpage;
            
        } else {
            //
        }
        
        WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
        request.userInfo = @{@"ShareMessageFrom": NSStringFromClass([self class])};
        [WeiboSDK sendRequest:request];
    }

}

#pragma mark - AIActionSheetDelegate
- (void)didSelectedActionSheet:( AIActionSheet *)actionSheet buttonIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex != buttonIndex) {
        inline_SharedPlatformScene *scene = [_scenes objectAtIndex:buttonIndex];
        if (scene.platform == AIPlatformWechat) {
            [self shareToWeixin:scene];
        } else if (scene.platform == AIPlatformQQ) {
            [self shareToQQ:scene];
        } else if (scene.platform == AIPlatformWeibo) {
            [self shareToWeibo:scene];
        }
    }
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if (_finishBlock) {
        _finishBlock(AIInvokingStatusCodeDone,response);
    }
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {}

- (void)handleSendQQResult:(QQApiSendResultCode)sendResult {
    switch (sendResult) {
        case EQQAPIAPPNOTREGISTED: {
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID: {
            break;
        }
        case EQQAPIQQNOTINSTALLED: {
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI: {
            if (_qqCallback.finishBlock) {
                _qqCallback.finishBlock(sendResult,nil);
            }
            break;
        }
        case EQQAPISENDFAILD: {
            break;
        }
        default:
        {
            break;
        }
    }
}

#pragma mark - TencentLoginDelegate
- (void)tencentDidLogin {}
- (void)tencentDidNotLogin:(BOOL)cancelled {}
- (void)tencentDidNotNetWork {}

@end

#if 1

#pragma mark - UIApplicationDelegate的钩子函数，不用修改！！！
@interface AIAppHook2Shared : NSObject
@end

@implementation AIAppHook2Shared

+ (void)hookMehod:(SEL)oldSEL andDef:(SEL)defaultSEL andNew:(SEL)newSEL {
    
    Class oldClass = objc_getClass([AppDelegateClassName UTF8String]);
    Class newClass = [self class];
    
    //把方法加给原Class
    class_addMethod(oldClass, newSEL, class_getMethodImplementation(newClass, newSEL), nil);
    class_addMethod(oldClass, oldSEL, class_getMethodImplementation(newClass, defaultSEL),nil);
    
    Method oldMethod = class_getInstanceMethod(oldClass, oldSEL);
    assert(oldMethod);
    Method newMethod = class_getInstanceMethod(oldClass, newSEL);
    assert(newMethod);
    method_exchangeImplementations(oldMethod, newMethod);
    
}

+ (void)load {
    
    [self hookMehod:@selector(application:didFinishLaunchingWithOptions:) andDef:@selector(defaultApplication:didFinishLaunchingWithOptions:) andNew:@selector(hookedApplication:didFinishLaunchingWithOptions:)];
    
    [self hookMehod:@selector(application:handleOpenURL:) andDef:@selector(defaultApplication:handleOpenURL:) andNew:@selector(hookedApplication:handleOpenURL:)];
    
    [self hookMehod:@selector(application:openURL:sourceApplication:annotation:) andDef:@selector(defaultApplication:openURL:sourceApplication:annotation:) andNew:@selector(hookedApplication:openURL:sourceApplication:annotation:)];
    
    [self hookMehod:@selector(application:openURL:options:) andDef:@selector(defaultApplication:openURL:options:) andNew:@selector(hookedApplication:openURL:options:)];
}

- (BOOL)hookedApplication:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)dic {
    [self hookedApplication:application didFinishLaunchingWithOptions:dic];
    [[SharedManager sharedManager] registerSharedSDKs];
    return YES;
}

- (BOOL)hookedApplication:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [self hookedApplication:application handleOpenURL:url];
    return [[SharedManager sharedManager] handleOpenURL:url];
}

- (BOOL)hookedApplication:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self hookedApplication:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    return [[SharedManager sharedManager] handleOpenURL:url];
}

- (BOOL)hookedApplication:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    [self hookedApplication:app openURL:url options:options];
    return [[SharedManager sharedManager] handleOpenURL:url];
}


#pragma mark - 默认
 - (BOOL)defaultApplication:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)dic { return YES;
}

- (BOOL)defaultApplication:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return YES;
}

- (BOOL)defaultApplication:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return YES;
}

-(BOOL)defaultApplication:(UIApplication*)application openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    return YES;
}

@end

#endif

