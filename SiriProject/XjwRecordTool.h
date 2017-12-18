//
//  XjwRecordTool.h
//  SiriProject
//
//  Created by xie on 2017/12/12.
//  Copyright © 2017年 abadou. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XjwRecordTool : NSObject
+(instancetype)defaultRecord;

-(void)startRecord;
- (void)stopRecord;
- (void)PlayRecord;
@end
