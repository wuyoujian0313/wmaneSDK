//
//  ANETypeConversion.h
//  wmaneSDK
//
//  Created by wuyoujian on 17/3/1.
//  Copyright © 2017年 Asiainfo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlashRuntimeExtensions.h"

@interface ANETypeConversion : NSObject

- (FREResult)FREObject2NString:(FREObject)object toNString:(NSString **)value;
- (FREResult)NString2FREObject:(NSString*)string toFREObject:(FREObject*)object;
- (FREResult)NSDate2FREObject:(NSDate*)date toFREOject:(FREObject*)object;
- (FREResult)FREObject2UIImage:(FREObject *)object toUIImage:(UIImage**)value;

- (FREResult)FREObject2NSUInteger:(FREObject)object toNSUInteger:(NSUInteger*)value;


- (UIImage*)thumbnailOfImage:(UIImage*)image withMaxSize:(float)maxsize;
- (FREObject)bool2FREObject:(BOOL)value;
@end
