//
//  XjwSiriPlayer.h
//  SiriProject
//
//  Created by xie on 2017/12/12.
//  Copyright © 2017年 abadou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface XjwSiriPlayer : NSObject
@property (nonatomic, assign) float rate;//语速
@property (nonatomic, assign) float volume; // 音量
@property (nonatomic, assign) float pitchMultiplier; // 音调
@property (nonatomic, assign) BOOL autoPlay; // 自动播放

+(instancetype)defaultSoundPlayer;
- (void)play:(NSString *)text;
// 是否正在播报语音
- (BOOL)isPlaying;

// 停止播报语音
- (void)stopNow;
@end
