//
//  DeallocHook.m
//  MulticastDelegate
//
//  Created by kemchenj on 2021/10/17.
//

#import "DeallocHook.h"

@implementation DeallocHook

- (instancetype)initWithHook:(void (^)(void))hook {
    self = [super init];
    if (self) {
        self.hook = hook;
    }
    return self;
}

@end
