//
//  ViewController.m
//  SpeachToText
//
//  Created by JimmyOu on 16/9/27.
//  Copyright © 2016年 JimmyOu. All rights reserved.
//

#import "ViewController.h"
#import "JOSpeechManager.h"
@interface ViewController ()<JOSpeechManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *recognizeBtn;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (nonatomic, strong) JOSpeechManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.resultTextView.text = @"说些什么吧！";
    _manager = [[JOSpeechManager alloc] initWithCompletionHandler:^(NSString *recognizedString, NSError *error, BOOL isFinal) {
        self.resultTextView.text = [recognizedString copy];
        NSLog(@"result = %@,error = %@,finish = %d",recognizedString,error,isFinal);
        if (isFinal) {
            self.recognizeBtn.enabled = YES;
        }
    }];
    _manager.delegate = self;
    [self.manager requestAuthorized:^(BOOL authorized) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           self.recognizeBtn.enabled = authorized;
        }];
    }];
}
- (IBAction)microphoneClick:(UIButton *)sender {
    [self.recognizeBtn setTitle:@"停止录音" forState:UIControlStateNormal];
    if ([self.manager isRuning]) {
        [self.manager pauseRecognizing];
        self.recognizeBtn.enabled = YES;
        [self.recognizeBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    } else {
        [self.manager startRecognizing];
        [self.recognizeBtn setTitle:@"停止录音" forState:UIControlStateNormal];
    }
    
}
- (void)speechManager:(JOSpeechManager *)manager availabilityDidChange:(BOOL)available {
    self.recognizeBtn.enabled = available;
}


@end
