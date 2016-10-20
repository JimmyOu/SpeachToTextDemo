//
//  JOSiriManager.m
//  SpeachToText
//
//  Created by JimmyOu on 16/10/19.
//  Copyright © 2016年 JimmyOu. All rights reserved.
//

#import "JOSiriManager.h"
#import <AVFoundation/AVFoundation.h>
@interface JOSiriManager () <SFSpeechRecognizerDelegate>
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *requestBuffer;
@property (nonatomic, strong) SFSpeechRecognitionTask *task;
@property (nonatomic, copy) SpeechRecognizeCompeltionHandler handler;
@property (nonatomic, strong) SFSpeechRecognizer *recognize;
@property (nonatomic, strong) NSTimer *timer;


@end
@implementation JOSiriManager
- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeout = 10.0;
    }
    return self;
}
- (void)record {
    //请求权限
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        if (status == SFSpeechRecognizerAuthorizationStatusAuthorized) {
            [self recognizeAudioBuffer];
        }
    }];
}
- (void)recognizeAudioBuffer {
    self.requestBuffer = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    self.requestBuffer.shouldReportPartialResults = NO;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryRecord error:&error];
    if (error) {
        NSLog(@"error = %@",error.localizedDescription);
        return;
    }
    [session setMode:AVAudioSessionModeMeasurement error:&error];
    if (error) {
        NSLog(@"error = %@",error.localizedDescription);
        return;
    }
    [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        NSLog(@"error = %@",error.localizedDescription);
        return;
    }
    
    if (!self.audioEngine.inputNode) {
        NSLog(@"error = 无输入节点");
        return;
        
    }
    
    
    [self.audioEngine.inputNode installTapOnBus:0 bufferSize:1024 format:[self.audioEngine.inputNode outputFormatForBus:0] block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        if (buffer) {
            [self.requestBuffer appendAudioPCMBuffer:buffer];
        }
    }];
    
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
}
- (void)startRecognizing:(void(^)())start WithCompletionHandler:(SpeechRecognizeCompeltionHandler)handler {
    self.handler = handler;
    [self.requestBuffer endAudio];
    if(start){
        start();
    }
    [self timer];
    [self.recognize recognitionTaskWithRequest:self.requestBuffer resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        [self.timer invalidate];
        self.timer = nil;
        if (result) {
            if (self.handler) {
                self.handler(result.bestTranscription.formattedString,nil,result.final);
            }
        }
        if (error) {
            if (self.handler) {
                self.handler(nil,error,YES);
            }
        }
    }];
}
- (void)finish {
    [self.requestBuffer endAudio];
    [self.task finish];
    [self.audioEngine stop];
    [self.audioEngine.inputNode removeTapOnBus:0];
    self.task = nil;
}
- (void)requestAuthorized:(void (^)(BOOL))block {
    __block BOOL speechAuthorized = NO;
    __block BOOL audioAuthrozied = NO;
    //请求麦克风
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        audioAuthrozied = granted;
    }];
    //请求语音识别
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                speechAuthorized = NO;
                NSLog(@"语音识别未授权");
                if (block) {
                    block(audioAuthrozied&speechAuthorized);
                }
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                speechAuthorized = NO;
                NSLog(@"语音识别被拒绝");
                if (block) {
                    block(audioAuthrozied&speechAuthorized);
                }
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                speechAuthorized = NO;
                NSLog(@"此设备不支持语音识别");
                if (block) {
                    block(audioAuthrozied&speechAuthorized);
                }
                break;
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                speechAuthorized = YES;
                NSLog(@"语音识别被授权");
                if (block) {
                    block(audioAuthrozied&speechAuthorized);
                }
                break;
        }
    }];
    
}
+ (SFSpeechRecognizerAuthorizationStatus)authorizationStatus {
    return [SFSpeechRecognizer authorizationStatus];
}
+ (BOOL)siriAuthorizationStatus {
    SFSpeechRecognizerAuthorizationStatus speechStatus = [self authorizationStatus];
    
   AVAuthorizationStatus captureStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if ((speechStatus == SFSpeechRecognizerAuthorizationStatusAuthorized) && (captureStatus == AVAuthorizationStatusAuthorized)) {
        return YES;
    } else {
        return NO;
    }
}
- (SFSpeechRecognizer *)recognize {
    if (!_recognize) {
        _recognize = [[SFSpeechRecognizer alloc] init];
        _recognize.delegate = self;
    }
    return _recognize;
}
- (AVAudioEngine *)audioEngine {
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (NSTimer *)timer {
    if (!_timer) {
        __weak __typeof(self)weakSelf = self;
        _timer = [NSTimer timerWithTimeInterval:_timeout repeats:NO block:^(NSTimer * _Nonnull timer) {
            [weakSelf finish];
            if ([weakSelf.delegate respondsToSelector:@selector(siriManagerTimeOut:)]){
                [weakSelf.delegate siriManagerTimeOut:weakSelf];
            }
        }];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (self.delegate && [self.delegate respondsToSelector:@selector(siriManager:availabilityDidChange:)]) {
        [self.delegate siriManager:self availabilityDidChange:available];
    }
}

@end
