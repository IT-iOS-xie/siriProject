//
//  XjwSiriPlayer.m
//  SiriProject
//
//  Created by xie on 2017/12/12.
//  Copyright © 2017年 abadou. All rights reserved.
//

#import "XjwSiriPlayer.h"

static XjwSiriPlayer * soundPlayer = nil;
@interface XjwSiriPlayer()

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@end
@implementation XjwSiriPlayer

+ (instancetype)defaultSoundPlayer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundPlayer = [[self alloc] init];
    });
    return soundPlayer;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (soundPlayer == nil) {
            soundPlayer = [super allocWithZone:zone];
        }
    });
    return soundPlayer;
}

- (BOOL)isPlaying {
    if ([self.synthesizer isSpeaking]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)play:(NSString *)text {
    if (![text isEqualToString:@""]) {
        self.synthesizer = [[AVSpeechSynthesizer alloc] init];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:text];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"]; // 设置语言
        utterance.volume = self.volume; // 设置音量 (0.0 ~ 1.0)
        
        NSString *strSysVersion = [[UIDevice currentDevice] systemVersion];
       
        if ([strSysVersion floatValue] > 9) {
            utterance.rate = self.rate ;//.5; // 设置语速
        } else {
            utterance.rate = self.rate;
        }
        utterance.pitchMultiplier = self.pitchMultiplier ;//1.0;
        utterance.postUtteranceDelay = 1;
        [self.synthesizer speakUtterance:utterance];
    }
}

- (void)stopNow {
    if ([self.synthesizer isSpeaking]) {
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@""];
        [self.synthesizer speakUtterance:utterance];
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}
@end
