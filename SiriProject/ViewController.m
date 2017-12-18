//
//  ViewController.m
//  SiriProject
//
//  Created by xie on 2017/12/12.
//  Copyright © 2017年 abadou. All rights reserved.
//

#import "ViewController.h"
#import "XjwSiriPlayer.h"
#import "XjwRecordTool.h"
@interface ViewController ()<SFSpeechRecognizerDelegate>


//SFSpeechAudioBufferRecognitionRequest:通过音频流来创建语音识别请求。
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

/*这个类是语音识别的操作类，用于语音识别用户权限的申请，语言环境的设置，语音模式的设置以及向Apple服务发送语音识别的请求。*/
@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic,strong) AVAudioEngine *audioEngine;
//SFSpeechRecognitionTask：这个类是语音识别服务请求任务类，每一个语音识别请求都可以抽象为一个SFSpeechRecognitionTask实例，其中SFSpeechRecognitionTaskDelegate协议中约定了许多请求任务过程中的监听方法。;
@property (nonatomic,strong) SFSpeechRecognitionTask *recognitionTask;
@property (weak, nonatomic) IBOutlet UILabel *siriLabel;
@property (weak, nonatomic) IBOutlet UILabel *recordLabel;
@property (weak, nonatomic) IBOutlet UIButton *speechBtn;
@property (weak, nonatomic) IBOutlet UIButton *unarchieveSpeechBtn;
@property (weak, nonatomic) IBOutlet UILabel *unarchieveResult;

@end

@implementation ViewController
- (IBAction)siriPlay:(id)sender {
    XjwSiriPlayer * player = [XjwSiriPlayer defaultSoundPlayer];
    player.rate = 0.5;
    player.volume = 1;
    player.pitchMultiplier = 1;
    if ([player isPlaying]) {
        [player stopNow];
          [player play:self.siriLabel.text];
    } else {
        
        [player play:self.siriLabel.text];
    }
  
    
}
- (IBAction)startRecord:(id)sender {
    
    XjwRecordTool * recordTool = [XjwRecordTool defaultRecord];
    [recordTool startRecord];
}
- (IBAction)stopRecord:(id)sender {
    XjwRecordTool * recordTool = [XjwRecordTool defaultRecord];
    [recordTool stopRecord];
}
- (IBAction)playRecordSound:(id)sender {
    XjwRecordTool * recordTool = [XjwRecordTool defaultRecord];
    [recordTool PlayRecord];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    weakSelf.speechBtn.enabled = NO;
                    [weakSelf.speechBtn setTitle:@"语音识别未授权" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    weakSelf.speechBtn.enabled = NO;
                    [weakSelf.speechBtn setTitle:@"用户未授权使用语音识别" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    weakSelf.speechBtn.enabled = NO;
                    [weakSelf.speechBtn setTitle:@"语音识别在这台设备上受到限制" forState:UIControlStateDisabled];
                    
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    weakSelf.speechBtn.enabled = YES;
                    [weakSelf.speechBtn setTitle:@"开始录音" forState:UIControlStateNormal];
                    break;
                    
                default:
                    break;
            }
            
        });
    }];
}

#pragma mark ---- siri录音按钮
- (IBAction)recordButtonClicked:(UIButton *)sender {
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        if (_recognitionRequest) {
            [_recognitionRequest endAudio];
        }
        self.speechBtn.enabled = NO;
        [self.speechBtn setTitle:@"正在停止" forState:UIControlStateDisabled];
        
    }
    else{
        [self startRecording];
        [self.speechBtn setTitle:@"停止录音" forState:UIControlStateNormal];
        
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadRecordText:) name:XJWRecordTimeReload object:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)reloadRecordText:(NSNotification*)noty{
    
    self.recordLabel.text = [NSString stringWithFormat:@"已录制%@s,文件大小为%@",noty.object[@"reloadTime"],noty.object[@"fileData"]];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)SpeechRecordBtnClick:(id)sender {
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
            strongSelf.unarchieveResult.text = result.bestTranscription.formattedString;
            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            strongSelf.recognitionTask = nil;
            strongSelf.recognitionRequest = nil;
            strongSelf.speechBtn.enabled = YES;
            [strongSelf.speechBtn setTitle:@"开始录音" forState:UIControlStateNormal];
        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
    self.unarchieveResult.text = @"正在录音。。。";
}
- (IBAction)recognizeLocalRecordFile:(id)sender {
    
    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    SFSpeechRecognizer *localRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
//    NSURL *url =[[NSBundle mainBundle] URLForResource:@"录音.m4a" withExtension:nil];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString * filePath = [path stringByAppendingString:@"/Record.wav"];
    NSURL * url =[NSURL fileURLWithPath:filePath];
    if (!url) return;
    SFSpeechURLRecognitionRequest *res =[[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    __weak typeof(self) weakSelf = self;
    [localRecognizer recognitionTaskWithRequest:res resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"语音识别解析失败,%@",error);
        }
        else
        {
            weakSelf.unarchieveResult.text = result.bestTranscription.formattedString;
        }
    }];
}

///开始录音
- (void)startRecording{
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
            strongSelf.unarchieveResult.text = result.bestTranscription.formattedString;
            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            strongSelf.recognitionTask = nil;
            strongSelf.recognitionRequest = nil;
            strongSelf.speechBtn.enabled = YES;
            [strongSelf.speechBtn setTitle:@"开始录音" forState:UIControlStateNormal];
        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception "之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
    self.unarchieveResult.text = @"正在录音。。。";
}
- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        //腰围语音识别对象设置语言，这里设置的是中文
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        
        _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}
#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        self.speechBtn.enabled = YES;
        [self.speechBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    }
    else{
        self.speechBtn.enabled = NO;
        [self.speechBtn setTitle:@"语音识别不可用" forState:UIControlStateDisabled];
    }
}


@end
