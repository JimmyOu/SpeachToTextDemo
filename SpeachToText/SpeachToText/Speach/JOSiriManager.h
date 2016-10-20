//
//  JOSiriManager.h
//  SpeachToText
//
//  Created by JimmyOu on 16/10/19.
//  Copyright © 2016年 JimmyOu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Speech/Speech.h>
typedef void(^SpeechRecognizeCompeltionHandler)(NSString *recognizedString,NSError *error,BOOL isFinal);
@protocol JOSiriManagerDelegate ;
@interface JOSiriManager : NSObject
@property (nonatomic, weak) id<JOSiriManagerDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 语音识别权限
 */
+ (SFSpeechRecognizerAuthorizationStatus)authorizationStatus;
+ (BOOL)siriAuthorizationStatus;

/**
    录音
 */
- (void)record;

/**
 开始识别
 */
- (void)startRecognizing:(void(^)())start WithCompletionHandler:(SpeechRecognizeCompeltionHandler)handler;

/**
 停止识别，释放资源
 */
- (void)finish;

/**
 请求语音识别需要的授权
 */
- (void)requestAuthorized:(void(^)(BOOL authorized))block;
@end
@protocol JOSiriManagerDelegate <NSObject>
@optional
- (void)siriManager:(JOSiriManager *)manager availabilityDidChange:(BOOL)available;
- (void)siriManagerTimeOut:(JOSiriManager *)manager ;
@end
