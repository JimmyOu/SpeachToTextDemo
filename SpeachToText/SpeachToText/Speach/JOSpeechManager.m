//
//  JOSpeechManager.m
//  SpeachToText
//
//  Created by JimmyOu on 16/9/27.
//  Copyright © 2016年 JimmyOu. All rights reserved.
//

#import "JOSpeechManager.h"
#import <Speech/Speech.h>
@interface JOSpeechManager ()<SFSpeechRecognizerDelegate>
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, copy) SpeechRecognizeCompeltionHandler handler;
@property (nonatomic, strong) AVAudioInputNode *input;
@end
@implementation JOSpeechManager
- (instancetype)initWithCompletionHandler:(SpeechRecognizeCompeltionHandler)handler {
    if (self = [super init]) {
        self.handler = handler;
        [self requestAuthorized:NULL];
    }
    return self;
}
- (instancetype)init {
    if (self = [super init]) {
        NSAssert(NO, @"use initWithCompletionHandler to initialize JOSpeechManager");
    }
    return self;
}
- (void)startRecognizing {
    [self startRecording];
}
- (void)pauseRecognizing {
    if ([self.audioEngine isRunning]) {
        [self.audioEngine stop];
        if (self.recognitionRequest) {
            [self.recognitionRequest endAudio];
        }
    }
}
- (BOOL)isRuning {
    return self.audioEngine.isRunning;
}
- (void)startRecording {
    if (self.recognitionTask) {  //1
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance]; //2
    NSError *error ;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        NSLog(@"audioSession properties weren't set because of an error.");
    }
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init]; //3

   self.input = [self.audioEngine inputNode];
    
    if (!self.input) {  //4
        NSLog(@"Audio engine has no input node");
    }
    if (!self.recognitionRequest) {  //5
        NSLog(@"Unable to create an SFSpeechAudioBufferRecognitionRequest object");
    }
    self.recognitionRequest.shouldReportPartialResults = YES;  //6
    
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {  //7

        BOOL isFinal = NO;
        if (result) {
            if(self.handler) {
                self.handler(result.bestTranscription.formattedString,error,isFinal);
                isFinal = result.isFinal;
            }
        }
        if (!error && isFinal) {
            [self stopRecognizing];
            if(self.handler){
            self.handler(nil,error,isFinal);
            }
        }
    }];
    
    AVAudioFormat *recordingFormat =  [self.input outputFormatForBus:0];
    [self.input installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
       if(self.recognitionRequest) [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [self.audioEngine prepare];
    NSError *startError ;
    [self.audioEngine startAndReturnError:&startError];
    if (startError) {
        NSLog(@"audioEngine couldn't start because of an error.");
    }
}
- (void)stopRecognizing {
    [self.audioEngine stop];
    [self.input removeTapOnBus:0];
    self.recognitionRequest = nil;
    self.recognitionTask = nil;
}

#pragma mark - speechRecognizer delegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(speechManager:availabilityDidChange:)]) {
        [self.delegate speechManager:self availabilityDidChange:available];
    }
}
- (void)requestAuthorized:(void (^)(BOOL))block {
    __block BOOL authorized = NO;
    //确认权限
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                authorized = NO;
                NSLog(@"语音识别未授权");
                if (block) {
                    block(authorized);
                }
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                authorized = NO;
                NSLog(@"语音识别被拒绝");
                if (block) {
                    block(authorized);
                }
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                authorized = NO;
                NSLog(@"此设备不支持语音识别");
                if (block) {
                    block(authorized);
                }
                break;
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                authorized = YES;
                NSLog(@"语音识别被授权");
                if (block) {
                    block(authorized);
                }
                break;
        }
    }];

}
- (AVAudioEngine *)audioEngine {
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer {
    if (!_speechRecognizer) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh-CN"]];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}
@end
