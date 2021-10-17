//
//  DeallocHook.h
//  MulticastDelegate
//
//  Created by kemchenj on 2021/10/17.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface DeallocHook : NSObject

@property(nonatomic, copy) void (^hook)(void);
- (instancetype)initWithHook:(void (^)(void))hook;

@end

NS_ASSUME_NONNULL_END
