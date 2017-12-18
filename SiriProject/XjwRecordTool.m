//
//  XjwRecordTool.m
//  SiriProject
//
//  Created by xie on 2017/12/12.
//  Copyright © 2017年 abadou. All rights reserved.
//

#import "XjwRecordTool.h"
  static XjwRecordTool * recordTool = nil;
# define COUNTDOWN 0

@interface XjwRecordTool()
{
    NSString * filePath;
    NSTimer * timer;
    NSInteger countDown ;
    NSInteger recordTime;
}
@property(nonatomic,strong)AVAudioSession *session;
@property(nonatomic,strong)NSURL * recordFileUrl;
@property(nonatomic,strong)AVAudioRecorder * recorder;

@property(nonatomic,strong)AVAudioPlayer * audioPlayer;
@end
@implementation XjwRecordTool
+(instancetype)defaultRecord{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recordTool = [[XjwRecordTool alloc]init];
    });
    return recordTool;
 
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recordTool = [super allocWithZone:zone];
    });
    return recordTool;
    
}

-(void)startRecord{
    NSLog(@"开始录音");
    countDown = 0;
 
    [self addTimer];
    
    AVAudioSession *session =[AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if (session == nil) {
        
        NSLog(@"Error creating session: %@",[sessionError description]);
        
    }else{
        [session setActive:YES error:nil];
        
    }
    
    self.session = session;
    
    
    //1.获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  filePath = [path stringByAppendingString:@"/Record.wav"];
    
    //2.获取文件路径
    self.recordFileUrl = [NSURL fileURLWithPath:filePath];
    
    //设置参数
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   //采样率  8000/11025/22050/44100/96000（影响音频的质量）
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey,
                                   // 音频格式
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   //采样位数  8、16、24、32 默认为16
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                   // 音频通道数 1 或 2
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                   //录音质量
                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
                                   nil];
    
    
    _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:recordSetting error:nil];
    
    if (_recorder) {
        
        _recorder.meteringEnabled = YES;
        [_recorder prepareToRecord];
        [_recorder record];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self stopRecord];
        });
        
        
        
    }else{
        NSLog(@"音频格式和文件存储格式不匹配,无法初始化Recorder");
        
    }
    
  
}

-(void)addTimer{
    timer  = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(reloadTimeText) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [timer fire];
    
    
}

-(void)reloadTimeText{
    countDown ++;
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        [[NSNotificationCenter defaultCenter]postNotificationName:XJWRecordTimeReload object:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)countDown],@"reloadTime",[NSString stringWithFormat:@"%.2f kb",[[manager attributesOfItemAtPath:filePath error:nil] fileSize]/1024.0],@"fileData", nil]];
    }
}
-(void)removeTimer{
    [timer invalidate];
    timer = nil;

}
- (void)stopRecord {
    
    [self removeTimer];
    NSLog(@"停止录音");
    
    if ([self.recorder isRecording]) {
        [self.recorder stop];
    }
    
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        
//        NSLog(@"%@", [NSString stringWithFormat:@"录了 %ld 秒,文件大小为 %.2fKb",COUNTDOWN - (long)countDown,[[manager attributesOfItemAtPath:filePath error:nil] fileSize]/1024.0]);
 
        
    }else{
        
       
    }
    
    
    
}
- (void)PlayRecord {
    
    NSLog(@"播放录音");
    [self.recorder stop];
    
    if ([self.audioPlayer isPlaying])return;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileUrl error:nil];
    
    
    
    NSLog(@"%li",self.audioPlayer.data.length/1024);
    
    
    
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.audioPlayer play];
    
    
    
    
}



@end
