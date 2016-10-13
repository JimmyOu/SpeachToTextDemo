//
//  JOSpeechManager.h
//  SpeachToText
//
//  Created by JimmyOu on 16/9/27.
//  Copyright © 2016年 JimmyOu. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol JOSpeechManagerDelegate;
typedef void(^SpeechRecognizeCompeltionHandler)(NSString *recognizedString,NSError *error,BOOL isFinal);
@interface JOSpeechManager : NSObject

- (instancetype)initWithCompletionHandler:(SpeechRecognizeCompeltionHandler)handler;
@property (nonatomic,readonly, getter = isRuning) BOOL runing;
@property (nonatomic, weak) id<JOSpeechManagerDelegate>delegate;
//开始识别
- (void)startRecognizing;
//暂停识别
- (void)pauseRecognizing;
//停止识别，回收资源
- (void)stopRecognizing;
//查看授权
- (void)requestAuthorized:(void(^)(BOOL authorized))block;

@end

@protocol JOSpeechManagerDelegate <NSObject>
@optional
- (void)speechManager:(JOSpeechManager *)manager availabilityDidChange:(BOOL)available;
@end
