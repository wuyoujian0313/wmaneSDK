//
//  SharedDataModel.h
//  CommonProject
//
//  Created by wuyoujian on 16/5/12.
//  Copyright © 2016年 wuyoujian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/* ！！！！！！！分享支持的类型说明 
 1、微信和新浪微博都支持SharedDataType定义的类型
 2、QQ目前为了QQ聊天和QQ空间统一，就都只是支持：
 SharedDataTypeText、SharedDataTypeImage、SharedDataTypeURL这4个类型的分享
 */

// ！！！！！！ 请注意上面支持的类型说明
typedef NS_ENUM(NSInteger,SharedDataType) {
    SharedDataTypeText,     // 文字分享
    SharedDataTypeImage,    // 图片分享
    SharedDataTypeURL,      // 网页分享
    SharedDataTypeMusic,    // 音乐分享
    SharedDataTypeVideo,    // 视频分享
};



@interface SharedDataModel : NSObject

// ！！！！！！ 请注意上面支持的类型说明
@property (nonatomic, assign) SharedDataType dataType;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;//描述&文字内容
@property (nonatomic, copy) NSString *url;// 有url的分享，例如：SharedDataTypeURL，SharedDataTypeMusic，SharedDataTypeVideo
@property (nonatomic, copy) NSString *lowBandUrl;// 有url的分享，例如：SharedDataTypeURL，SharedDataTypeMusic，SharedDataTypeVideo
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) UIImage *thumbImage;


@end
